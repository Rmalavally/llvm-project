//===----------------------- SIFrameLowering.cpp --------------------------===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//==-----------------------------------------------------------------------===//

#include "SIFrameLowering.h"
#include "AMDGPUSubtarget.h"
#include "SIInstrInfo.h"
#include "SIMachineFunctionInfo.h"
#include "SIRegisterInfo.h"
#include "MCTargetDesc/AMDGPUMCTargetDesc.h"

#include "llvm/BinaryFormat/Dwarf.h"
#include "llvm/CodeGen/LivePhysRegs.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineFunction.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineModuleInfo.h"
#include "llvm/CodeGen/RegisterScavenging.h"
#include "llvm/MC/MCDwarf.h"
#include "llvm/Support/LEB128.h"

using namespace llvm;

#define DEBUG_TYPE "frame-info"


static ArrayRef<MCPhysReg> getAllSGPR128(const GCNSubtarget &ST,
                                         const MachineFunction &MF) {
  return makeArrayRef(AMDGPU::SGPR_128RegClass.begin(),
                      ST.getMaxNumSGPRs(MF) / 4);
}

// Find a scratch register that we can use at the start of the prologue to
// re-align the stack pointer. We avoid using callee-save registers since they
// may appear to be free when this is called from canUseAsPrologue (during
// shrink wrapping), but then no longer be free when this is called from
// emitPrologue.
//
// FIXME: This is a bit conservative, since in the above case we could use one
// of the callee-save registers as a scratch temp to re-align the stack pointer,
// but we would then have to make sure that we were in fact saving at least one
// callee-save register in the prologue, which is additional complexity that
// doesn't seem worth the benefit.
static unsigned findScratchNonCalleeSaveRegister(MachineRegisterInfo &MRI,
                                                 LivePhysRegs &LiveRegs,
                                                 const TargetRegisterClass &RC,
                                                 bool Unused = false) {
  // Mark callee saved registers as used so we will not choose them.
  const MCPhysReg *CSRegs = MRI.getCalleeSavedRegs();
  for (unsigned i = 0; CSRegs[i]; ++i)
    LiveRegs.addReg(CSRegs[i]);

  if (Unused) {
    // We are looking for a register that can be used throughout the entire
    // function, so any use is unacceptable.
    for (unsigned Reg : RC) {
      if (!MRI.isPhysRegUsed(Reg) && LiveRegs.available(MRI, Reg))
        return Reg;
    }
  } else {
    for (unsigned Reg : RC) {
      if (LiveRegs.available(MRI, Reg))
        return Reg;
    }
  }

  // If we require an unused register, this is used in contexts where failure is
  // an option and has an alternative plan. In other contexts, this must
  // succeed0.
  if (!Unused)
    report_fatal_error("failed to find free scratch register");

  return AMDGPU::NoRegister;
}

static MCPhysReg findUnusedSGPRNonCalleeSaved(MachineRegisterInfo &MRI) {
  LivePhysRegs LiveRegs;
  LiveRegs.init(*MRI.getTargetRegisterInfo());
  return findScratchNonCalleeSaveRegister(
    MRI, LiveRegs, AMDGPU::SReg_32_XM0_XEXECRegClass, true);
}

// We need to specially emit stack operations here because a different frame
// register is used than in the rest of the function, as getFrameRegister would
// use.
static void buildPrologSpill(LivePhysRegs &LiveRegs, MachineBasicBlock &MBB,
                             MachineBasicBlock::iterator I,
                             const SIInstrInfo *TII, unsigned SpillReg,
                             unsigned ScratchRsrcReg, unsigned SPReg, int FI) {
  MachineFunction *MF = MBB.getParent();
  MachineFrameInfo &MFI = MF->getFrameInfo();

  int64_t Offset = MFI.getObjectOffset(FI);

  MachineMemOperand *MMO = MF->getMachineMemOperand(
      MachinePointerInfo::getFixedStack(*MF, FI), MachineMemOperand::MOStore, 4,
      MFI.getObjectAlign(FI));

  if (isUInt<12>(Offset)) {
    BuildMI(MBB, I, DebugLoc(), TII->get(AMDGPU::BUFFER_STORE_DWORD_OFFSET))
      .addReg(SpillReg, RegState::Kill)
      .addReg(ScratchRsrcReg)
      .addReg(SPReg)
      .addImm(Offset)
      .addImm(0) // glc
      .addImm(0) // slc
      .addImm(0) // tfe
      .addImm(0) // dlc
      .addImm(0) // swz
      .addMemOperand(MMO);
    return;
  }

  MCPhysReg OffsetReg = findScratchNonCalleeSaveRegister(
    MF->getRegInfo(), LiveRegs, AMDGPU::VGPR_32RegClass);

  BuildMI(MBB, I, DebugLoc(), TII->get(AMDGPU::V_MOV_B32_e32), OffsetReg)
    .addImm(Offset);

  BuildMI(MBB, I, DebugLoc(), TII->get(AMDGPU::BUFFER_STORE_DWORD_OFFEN))
    .addReg(SpillReg, RegState::Kill)
    .addReg(OffsetReg, RegState::Kill)
    .addReg(ScratchRsrcReg)
    .addReg(SPReg)
    .addImm(0)
    .addImm(0) // glc
    .addImm(0) // slc
    .addImm(0) // tfe
    .addImm(0) // dlc
    .addImm(0) // swz
    .addMemOperand(MMO);
}

static void buildEpilogReload(LivePhysRegs &LiveRegs, MachineBasicBlock &MBB,
                              MachineBasicBlock::iterator I,
                              const SIInstrInfo *TII, unsigned SpillReg,
                              unsigned ScratchRsrcReg, unsigned SPReg, int FI) {
  MachineFunction *MF = MBB.getParent();
  MachineFrameInfo &MFI = MF->getFrameInfo();
  int64_t Offset = MFI.getObjectOffset(FI);

  MachineMemOperand *MMO = MF->getMachineMemOperand(
      MachinePointerInfo::getFixedStack(*MF, FI), MachineMemOperand::MOLoad, 4,
      MFI.getObjectAlign(FI));

  if (isUInt<12>(Offset)) {
    BuildMI(MBB, I, DebugLoc(),
            TII->get(AMDGPU::BUFFER_LOAD_DWORD_OFFSET), SpillReg)
      .addReg(ScratchRsrcReg)
      .addReg(SPReg)
      .addImm(Offset)
      .addImm(0) // glc
      .addImm(0) // slc
      .addImm(0) // tfe
      .addImm(0) // dlc
      .addImm(0) // swz
      .addMemOperand(MMO);
    return;
  }

  MCPhysReg OffsetReg = findScratchNonCalleeSaveRegister(
    MF->getRegInfo(), LiveRegs, AMDGPU::VGPR_32RegClass);

  BuildMI(MBB, I, DebugLoc(), TII->get(AMDGPU::V_MOV_B32_e32), OffsetReg)
    .addImm(Offset);

  BuildMI(MBB, I, DebugLoc(),
          TII->get(AMDGPU::BUFFER_LOAD_DWORD_OFFEN), SpillReg)
    .addReg(OffsetReg, RegState::Kill)
    .addReg(ScratchRsrcReg)
    .addReg(SPReg)
    .addImm(0)
    .addImm(0) // glc
    .addImm(0) // slc
    .addImm(0) // tfe
    .addImm(0) // dlc
    .addImm(0) // swz
    .addMemOperand(MMO);
}

// Emit flat scratch setup code, assuming `MFI->hasFlatScratchInit()`
void SIFrameLowering::emitEntryFunctionFlatScratchInit(
    MachineFunction &MF, MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
    const DebugLoc &DL, Register ScratchWaveOffsetReg) const {
  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIInstrInfo *TII = ST.getInstrInfo();
  const SIRegisterInfo *TRI = &TII->getRegisterInfo();
  const SIMachineFunctionInfo *MFI = MF.getInfo<SIMachineFunctionInfo>();

  // We don't need this if we only have spills since there is no user facing
  // scratch.

  // TODO: If we know we don't have flat instructions earlier, we can omit
  // this from the input registers.
  //
  // TODO: We only need to know if we access scratch space through a flat
  // pointer. Because we only detect if flat instructions are used at all,
  // this will be used more often than necessary on VI.

  Register FlatScratchInitReg =
      MFI->getPreloadedReg(AMDGPUFunctionArgInfo::FLAT_SCRATCH_INIT);

  MachineRegisterInfo &MRI = MF.getRegInfo();
  MRI.addLiveIn(FlatScratchInitReg);
  MBB.addLiveIn(FlatScratchInitReg);

  Register FlatScrInitLo = TRI->getSubReg(FlatScratchInitReg, AMDGPU::sub0);
  Register FlatScrInitHi = TRI->getSubReg(FlatScratchInitReg, AMDGPU::sub1);

  // Do a 64-bit pointer add.
  if (ST.flatScratchIsPointer()) {
    if (ST.getGeneration() >= AMDGPUSubtarget::GFX10) {
      BuildMI(MBB, I, DL, TII->get(AMDGPU::S_ADD_U32), FlatScrInitLo)
        .addReg(FlatScrInitLo)
        .addReg(ScratchWaveOffsetReg);
      BuildMI(MBB, I, DL, TII->get(AMDGPU::S_ADDC_U32), FlatScrInitHi)
        .addReg(FlatScrInitHi)
        .addImm(0);
      BuildMI(MBB, I, DL, TII->get(AMDGPU::S_SETREG_B32)).
        addReg(FlatScrInitLo).
        addImm(int16_t(AMDGPU::Hwreg::ID_FLAT_SCR_LO |
                       (31 << AMDGPU::Hwreg::WIDTH_M1_SHIFT_)));
      BuildMI(MBB, I, DL, TII->get(AMDGPU::S_SETREG_B32)).
        addReg(FlatScrInitHi).
        addImm(int16_t(AMDGPU::Hwreg::ID_FLAT_SCR_HI |
                       (31 << AMDGPU::Hwreg::WIDTH_M1_SHIFT_)));
      return;
    }

    BuildMI(MBB, I, DL, TII->get(AMDGPU::S_ADD_U32), AMDGPU::FLAT_SCR_LO)
      .addReg(FlatScrInitLo)
      .addReg(ScratchWaveOffsetReg);
    BuildMI(MBB, I, DL, TII->get(AMDGPU::S_ADDC_U32), AMDGPU::FLAT_SCR_HI)
      .addReg(FlatScrInitHi)
      .addImm(0);

    return;
  }

  assert(ST.getGeneration() < AMDGPUSubtarget::GFX10);

  // Copy the size in bytes.
  BuildMI(MBB, I, DL, TII->get(AMDGPU::COPY), AMDGPU::FLAT_SCR_LO)
    .addReg(FlatScrInitHi, RegState::Kill);

  // Add wave offset in bytes to private base offset.
  // See comment in AMDKernelCodeT.h for enable_sgpr_flat_scratch_init.
  BuildMI(MBB, I, DL, TII->get(AMDGPU::S_ADD_U32), FlatScrInitLo)
    .addReg(FlatScrInitLo)
    .addReg(ScratchWaveOffsetReg);

  // Convert offset to 256-byte units.
  BuildMI(MBB, I, DL, TII->get(AMDGPU::S_LSHR_B32), AMDGPU::FLAT_SCR_HI)
    .addReg(FlatScrInitLo, RegState::Kill)
    .addImm(8);
}

// Shift down registers reserved for the scratch RSRC.
Register SIFrameLowering::getEntryFunctionReservedScratchRsrcReg(
    MachineFunction &MF, Register ScratchWaveOffsetReg) const {

  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIInstrInfo *TII = ST.getInstrInfo();
  const SIRegisterInfo *TRI = &TII->getRegisterInfo();
  MachineRegisterInfo &MRI = MF.getRegInfo();
  SIMachineFunctionInfo *MFI = MF.getInfo<SIMachineFunctionInfo>();

  assert(MFI->isEntryFunction());

  Register ScratchRsrcReg = MFI->getScratchRSrcReg();

  if (ScratchRsrcReg == AMDGPU::NoRegister ||
      !MRI.isPhysRegUsed(ScratchRsrcReg))
    return AMDGPU::NoRegister;

  if (ST.hasSGPRInitBug() ||
      ScratchRsrcReg != TRI->reservedPrivateSegmentBufferReg(MF))
    return ScratchRsrcReg;

  // We reserved the last registers for this. Shift it down to the end of those
  // which were actually used.
  //
  // FIXME: It might be safer to use a pseudoregister before replacement.

  // FIXME: We should be able to eliminate unused input registers. We only
  // cannot do this for the resources required for scratch access. For now we
  // skip over user SGPRs and may leave unused holes.

  unsigned NumPreloaded = (MFI->getNumPreloadedSGPRs() + 3) / 4;
  ArrayRef<MCPhysReg> AllSGPR128s = getAllSGPR128(ST, MF);
  AllSGPR128s = AllSGPR128s.slice(std::min(static_cast<unsigned>(AllSGPR128s.size()), NumPreloaded));

  // Skip the last N reserved elements because they should have already been
  // reserved for VCC etc.
  for (MCPhysReg Reg : AllSGPR128s) {
    // Pick the first unallocated one. Make sure we don't clobber the other
    // reserved input we needed.
    //
    // FIXME: The preloaded SGPR count is not accurate for shaders as the
    // scratch wave offset may be in a fixed SGPR or
    // SITargetLowering::allocateSystemSGPRs may choose some free SGPR for the
    // scratch wave offset. We explicitly avoid the scratch wave offset to
    // account for this.
    if (!MRI.isPhysRegUsed(Reg) && MRI.isAllocatable(Reg) &&
        !TRI->isSubRegisterEq(Reg, ScratchWaveOffsetReg)) {
      MRI.replaceRegWith(ScratchRsrcReg, Reg);
      MFI->setScratchRSrcReg(Reg);
      return Reg;
    }
  }

  return ScratchRsrcReg;
}

void SIFrameLowering::emitEntryFunctionPrologue(MachineFunction &MF,
                                                MachineBasicBlock &MBB) const {
  assert(&MF.front() == &MBB && "Shrink-wrapping not yet supported");

  // FIXME: If we only have SGPR spills, we won't actually be using scratch
  // memory since these spill to VGPRs. We should be cleaning up these unused
  // SGPR spill frame indices somewhere.

  // FIXME: We still have implicit uses on SGPR spill instructions in case they
  // need to spill to vector memory. It's likely that will not happen, but at
  // this point it appears we need the setup. This part of the prolog should be
  // emitted after frame indices are eliminated.

  // FIXME: Remove all of the isPhysRegUsed checks

  SIMachineFunctionInfo *MFI = MF.getInfo<SIMachineFunctionInfo>();
  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIInstrInfo *TII = ST.getInstrInfo();
  MachineRegisterInfo &MRI = MF.getRegInfo();
  const Function &F = MF.getFunction();
  const MCRegisterInfo *MCRI = MF.getMMI().getContext().getRegisterInfo();

  assert(MFI->isEntryFunction());

  Register ScratchWaveOffsetReg = MFI->getPreloadedReg(
      AMDGPUFunctionArgInfo::PRIVATE_SEGMENT_WAVE_BYTE_OFFSET);
  // FIXME: Hack to not crash in situations which emitted an error.
  if (ScratchWaveOffsetReg == AMDGPU::NoRegister)
    return;

  // We need to do the replacement of the private segment buffer register even
  // if there are no stack objects. There could be stores to undef or a
  // constant without an associated object.
  //
  // This will return `AMDGPU::NoRegister` in cases where there are no actual
  // uses of the SRSRC.
  Register ScratchRsrcReg =
      getEntryFunctionReservedScratchRsrcReg(MF, ScratchWaveOffsetReg);

  // Make the selected register live throughout the function.
  if (ScratchRsrcReg != AMDGPU::NoRegister) {
    for (MachineBasicBlock &OtherBB : MF) {
      if (&OtherBB != &MBB) {
        OtherBB.addLiveIn(ScratchRsrcReg);
      }
    }
  }

  // Now that we have fixed the reserved SRSRC we need to locate the
  // (potentially) preloaded SRSRC.
  Register PreloadedScratchRsrcReg = AMDGPU::NoRegister;
  if (ST.isAmdHsaOrMesa(F)) {
    PreloadedScratchRsrcReg =
        MFI->getPreloadedReg(AMDGPUFunctionArgInfo::PRIVATE_SEGMENT_BUFFER);
    if (ScratchRsrcReg != AMDGPU::NoRegister &&
        PreloadedScratchRsrcReg != AMDGPU::NoRegister) {
      // We added live-ins during argument lowering, but since they were not
      // used they were deleted. We're adding the uses now, so add them back.
      MRI.addLiveIn(PreloadedScratchRsrcReg);
      MBB.addLiveIn(PreloadedScratchRsrcReg);
    }
  }

  // Debug location must be unknown since the first debug location is used to
  // determine the end of the prologue.
  DebugLoc DL;
  MachineBasicBlock::iterator I = MBB.begin();

  // On entry the SP/FP are not set up, so we need to define the CFA in terms
  // of a literal location expression.
  static const char CFAEncodedInst[] = {
      dwarf::DW_CFA_def_cfa_expression,
      3, // length
      static_cast<char>(dwarf::DW_OP_lit0),
      static_cast<char>(
          dwarf::DW_OP_lit6), // DW_ASPACE_AMDGPU_private_wave FIXME:
                              // should be defined elsewhere
      static_cast<char>(dwarf::DW_OP_LLVM_form_aspace_address)};
  buildCFI(MBB, I, DL,
           MCCFIInstruction::createEscape(
               nullptr, StringRef(CFAEncodedInst, sizeof(CFAEncodedInst))));
  // Unwinding halts when the return address (PC) is undefined.
  buildCFI(MBB, I, DL,
           MCCFIInstruction::createUndefined(
               nullptr, MCRI->getDwarfRegNum(AMDGPU::PC_REG, false)));

  if (MF.getFrameInfo().hasCalls()) {
    Register SPReg = MFI->getStackPtrOffsetReg();
    assert(SPReg != AMDGPU::SP_REG);
    BuildMI(MBB, I, DL, TII->get(AMDGPU::S_MOV_B32), SPReg)
        .addImm(MF.getFrameInfo().getStackSize() * ST.getWavefrontSize());
  }

  if (hasFP(MF)) {
    Register FPReg = MFI->getFrameOffsetReg();
    assert(FPReg != AMDGPU::FP_REG);
    BuildMI(MBB, I, DL, TII->get(AMDGPU::S_MOV_B32), FPReg).addImm(0);
  }

  if (MFI->hasFlatScratchInit() || ScratchRsrcReg != AMDGPU::NoRegister) {
    MRI.addLiveIn(ScratchWaveOffsetReg);
    MBB.addLiveIn(ScratchWaveOffsetReg);
  }

  if (MFI->hasFlatScratchInit()) {
    emitEntryFunctionFlatScratchInit(MF, MBB, I, DL, ScratchWaveOffsetReg);
  }

  if (ScratchRsrcReg != AMDGPU::NoRegister) {
    emitEntryFunctionScratchRsrcRegSetup(MF, MBB, I, DL,
                                         PreloadedScratchRsrcReg,
                                         ScratchRsrcReg, ScratchWaveOffsetReg);
  }
}

// Emit scratch RSRC setup code, assuming `ScratchRsrcReg != AMDGPU::NoReg`
void SIFrameLowering::emitEntryFunctionScratchRsrcRegSetup(
    MachineFunction &MF, MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
    const DebugLoc &DL, Register PreloadedScratchRsrcReg,
    Register ScratchRsrcReg, Register ScratchWaveOffsetReg) const {

  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIInstrInfo *TII = ST.getInstrInfo();
  const SIRegisterInfo *TRI = &TII->getRegisterInfo();
  const SIMachineFunctionInfo *MFI = MF.getInfo<SIMachineFunctionInfo>();
  const Function &Fn = MF.getFunction();

  if (ST.isAmdPalOS()) {
    // The pointer to the GIT is formed from the offset passed in and either
    // the amdgpu-git-ptr-high function attribute or the top part of the PC
    Register RsrcLo = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub0);
    Register RsrcHi = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub1);
    Register Rsrc01 = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub0_sub1);

    const MCInstrDesc &SMovB32 = TII->get(AMDGPU::S_MOV_B32);

    if (MFI->getGITPtrHigh() != 0xffffffff) {
      BuildMI(MBB, I, DL, SMovB32, RsrcHi)
        .addImm(MFI->getGITPtrHigh())
        .addReg(ScratchRsrcReg, RegState::ImplicitDefine);
    } else {
      const MCInstrDesc &GetPC64 = TII->get(AMDGPU::S_GETPC_B64);
      BuildMI(MBB, I, DL, GetPC64, Rsrc01);
    }
    auto GitPtrLo = AMDGPU::SGPR0; // Low GIT address passed in
    if (ST.hasMergedShaders()) {
      switch (MF.getFunction().getCallingConv()) {
        case CallingConv::AMDGPU_HS:
        case CallingConv::AMDGPU_GS:
          // Low GIT address is passed in s8 rather than s0 for an LS+HS or
          // ES+GS merged shader on gfx9+.
          GitPtrLo = AMDGPU::SGPR8;
          break;
        default:
          break;
      }
    }
    MF.getRegInfo().addLiveIn(GitPtrLo);
    MBB.addLiveIn(GitPtrLo);
    BuildMI(MBB, I, DL, SMovB32, RsrcLo)
      .addReg(GitPtrLo)
      .addReg(ScratchRsrcReg, RegState::ImplicitDefine);

    // We now have the GIT ptr - now get the scratch descriptor from the entry
    // at offset 0 (or offset 16 for a compute shader).
    MachinePointerInfo PtrInfo(AMDGPUAS::CONSTANT_ADDRESS);
    const MCInstrDesc &LoadDwordX4 = TII->get(AMDGPU::S_LOAD_DWORDX4_IMM);
    auto MMO = MF.getMachineMemOperand(PtrInfo,
                                       MachineMemOperand::MOLoad |
                                           MachineMemOperand::MOInvariant |
                                           MachineMemOperand::MODereferenceable,
                                       16, Align(4));
    unsigned Offset = Fn.getCallingConv() == CallingConv::AMDGPU_CS ? 16 : 0;
    const GCNSubtarget &Subtarget = MF.getSubtarget<GCNSubtarget>();
    unsigned EncodedOffset = AMDGPU::convertSMRDOffsetUnits(Subtarget, Offset);
    BuildMI(MBB, I, DL, LoadDwordX4, ScratchRsrcReg)
      .addReg(Rsrc01)
      .addImm(EncodedOffset) // offset
      .addImm(0) // glc
      .addImm(0) // dlc
      .addReg(ScratchRsrcReg, RegState::ImplicitDefine)
      .addMemOperand(MMO);
  } else if (ST.isMesaGfxShader(Fn) ||
             (PreloadedScratchRsrcReg == AMDGPU::NoRegister)) {
    assert(!ST.isAmdHsaOrMesa(Fn));
    const MCInstrDesc &SMovB32 = TII->get(AMDGPU::S_MOV_B32);

    Register Rsrc2 = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub2);
    Register Rsrc3 = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub3);

    // Use relocations to get the pointer, and setup the other bits manually.
    uint64_t Rsrc23 = TII->getScratchRsrcWords23();

    if (MFI->hasImplicitBufferPtr()) {
      Register Rsrc01 = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub0_sub1);

      if (AMDGPU::isCompute(MF.getFunction().getCallingConv())) {
        const MCInstrDesc &Mov64 = TII->get(AMDGPU::S_MOV_B64);

        BuildMI(MBB, I, DL, Mov64, Rsrc01)
          .addReg(MFI->getImplicitBufferPtrUserSGPR())
          .addReg(ScratchRsrcReg, RegState::ImplicitDefine);
      } else {
        const MCInstrDesc &LoadDwordX2 = TII->get(AMDGPU::S_LOAD_DWORDX2_IMM);

        MachinePointerInfo PtrInfo(AMDGPUAS::CONSTANT_ADDRESS);
        auto MMO = MF.getMachineMemOperand(
            PtrInfo,
            MachineMemOperand::MOLoad | MachineMemOperand::MOInvariant |
                MachineMemOperand::MODereferenceable,
            8, Align(4));
        BuildMI(MBB, I, DL, LoadDwordX2, Rsrc01)
          .addReg(MFI->getImplicitBufferPtrUserSGPR())
          .addImm(0) // offset
          .addImm(0) // glc
          .addImm(0) // dlc
          .addMemOperand(MMO)
          .addReg(ScratchRsrcReg, RegState::ImplicitDefine);

        MF.getRegInfo().addLiveIn(MFI->getImplicitBufferPtrUserSGPR());
        MBB.addLiveIn(MFI->getImplicitBufferPtrUserSGPR());
      }
    } else {
      Register Rsrc0 = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub0);
      Register Rsrc1 = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub1);

      BuildMI(MBB, I, DL, SMovB32, Rsrc0)
        .addExternalSymbol("SCRATCH_RSRC_DWORD0")
        .addReg(ScratchRsrcReg, RegState::ImplicitDefine);

      BuildMI(MBB, I, DL, SMovB32, Rsrc1)
        .addExternalSymbol("SCRATCH_RSRC_DWORD1")
        .addReg(ScratchRsrcReg, RegState::ImplicitDefine);

    }

    BuildMI(MBB, I, DL, SMovB32, Rsrc2)
      .addImm(Rsrc23 & 0xffffffff)
      .addReg(ScratchRsrcReg, RegState::ImplicitDefine);

    BuildMI(MBB, I, DL, SMovB32, Rsrc3)
      .addImm(Rsrc23 >> 32)
      .addReg(ScratchRsrcReg, RegState::ImplicitDefine);
  } else if (ST.isAmdHsaOrMesa(Fn)) {
    assert(PreloadedScratchRsrcReg != AMDGPU::NoRegister);

    if (ScratchRsrcReg != PreloadedScratchRsrcReg) {
      BuildMI(MBB, I, DL, TII->get(AMDGPU::COPY), ScratchRsrcReg)
          .addReg(PreloadedScratchRsrcReg, RegState::Kill);
    }
  }

  // Add the scratch wave offset into the scratch RSRC.
  //
  // We only want to update the first 48 bits, which is the base address
  // pointer, without touching the adjacent 16 bits of flags. We know this add
  // cannot carry-out from bit 47, otherwise the scratch allocation would be
  // impossible to fit in the 48-bit global address space.
  //
  // TODO: Evaluate if it is better to just construct an SRD using the flat
  // scratch init and some constants rather than update the one we are passed.
  Register ScratchRsrcSub0 = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub0);
  Register ScratchRsrcSub1 = TRI->getSubReg(ScratchRsrcReg, AMDGPU::sub1);

  // We cannot Kill ScratchWaveOffsetReg here because we allow it to be used in
  // the kernel body via inreg arguments.
  BuildMI(MBB, I, DL, TII->get(AMDGPU::S_ADD_U32), ScratchRsrcSub0)
      .addReg(ScratchRsrcSub0)
      .addReg(ScratchWaveOffsetReg)
      .addReg(ScratchRsrcReg, RegState::ImplicitDefine);
  BuildMI(MBB, I, DL, TII->get(AMDGPU::S_ADDC_U32), ScratchRsrcSub1)
      .addReg(ScratchRsrcSub1)
      .addImm(0)
      .addReg(ScratchRsrcReg, RegState::ImplicitDefine);
}

bool SIFrameLowering::isSupportedStackID(TargetStackID::Value ID) const {
  switch (ID) {
  case TargetStackID::Default:
  case TargetStackID::NoAlloc:
  case TargetStackID::SGPRSpill:
    return true;
  case TargetStackID::SVEVector:
    return false;
  }
  llvm_unreachable("Invalid TargetStackID::Value");
}

void SIFrameLowering::emitPrologueEntryCFI(MachineBasicBlock &MBB,
                                           MachineBasicBlock::iterator MBBI,
                                           const DebugLoc &DL) const {
  const MachineFunction &MF = *MBB.getParent();
  const MachineRegisterInfo &MRI = MF.getRegInfo();
  const MCRegisterInfo *MCRI = MF.getMMI().getContext().getRegisterInfo();
  Register StackPtrReg =
      MF.getInfo<SIMachineFunctionInfo>()->getStackPtrOffsetReg();

  // DW_ASPACE_AMDGPU_private_wave FIXME: should be defined elsewhere
  buildCFI(MBB, MBBI, DL,
           MCCFIInstruction::createLLVMDefAspaceCfa(
               nullptr, MCRI->getDwarfRegNum(StackPtrReg, false), 0, 6));

  static const char PCEncodedInst[] = {
      dwarf::DW_CFA_expression,
      16, // PC 64
      8,  // length
      static_cast<char>(dwarf::DW_OP_regx),
      62, // SGPR30
      static_cast<char>(dwarf::DW_OP_piece),
      4, // 32 bits
      static_cast<char>(dwarf::DW_OP_regx),
      63, // SGPR31
      static_cast<char>(dwarf::DW_OP_piece),
      4 // 32 bits
  };
  buildCFI(MBB, MBBI, DL,
           MCCFIInstruction::createEscape(
               nullptr, StringRef(PCEncodedInst, sizeof(PCEncodedInst))));

  static const MCPhysReg CallerSavedRegs[] = {
      AMDGPU::VGPR0,     AMDGPU::VGPR1,  AMDGPU::VGPR2,  AMDGPU::VGPR3,
      AMDGPU::VGPR4,     AMDGPU::VGPR5,  AMDGPU::VGPR6,  AMDGPU::VGPR7,
      AMDGPU::VGPR8,     AMDGPU::VGPR9,  AMDGPU::VGPR10, AMDGPU::VGPR11,
      AMDGPU::VGPR12,    AMDGPU::VGPR13, AMDGPU::VGPR14, AMDGPU::VGPR15,
      AMDGPU::VGPR16,    AMDGPU::VGPR17, AMDGPU::VGPR18, AMDGPU::VGPR19,
      AMDGPU::VGPR20,    AMDGPU::VGPR21, AMDGPU::VGPR22, AMDGPU::VGPR23,
      AMDGPU::VGPR24,    AMDGPU::VGPR25, AMDGPU::VGPR26, AMDGPU::VGPR27,
      AMDGPU::VGPR28,    AMDGPU::VGPR29, AMDGPU::VGPR30, AMDGPU::VGPR31,
      AMDGPU::SGPR0,     AMDGPU::SGPR1,  AMDGPU::SGPR2,  AMDGPU::SGPR3,
      AMDGPU::SGPR4,     AMDGPU::SGPR5,  AMDGPU::SGPR6,  AMDGPU::SGPR7,
      AMDGPU::SGPR8,     AMDGPU::SGPR9,  AMDGPU::SGPR10, AMDGPU::SGPR11,
      AMDGPU::SGPR12,    AMDGPU::SGPR13, AMDGPU::SGPR14, AMDGPU::SGPR15,
      AMDGPU::SGPR16,    AMDGPU::SGPR17, AMDGPU::SGPR18, AMDGPU::SGPR19,
      AMDGPU::SGPR20,    AMDGPU::SGPR21, AMDGPU::SGPR22, AMDGPU::SGPR23,
      AMDGPU::SGPR24,    AMDGPU::SGPR25, AMDGPU::SGPR26, AMDGPU::SGPR27,
      AMDGPU::SGPR28,    AMDGPU::SGPR29, AMDGPU::SGPR30, AMDGPU::SGPR31,
      AMDGPU::NoRegister};
  for (int I = 0; CallerSavedRegs[I]; ++I) {
    if (!MRI.isPhysRegModified(CallerSavedRegs[I]))
      continue;
    MCRegister DwarfReg = MCRI->getDwarfRegNum(CallerSavedRegs[I], false);
    buildCFI(MBB, MBBI, DL,
             MCCFIInstruction::createUndefined(nullptr, DwarfReg));
  }
};

void SIFrameLowering::emitPrologue(MachineFunction &MF,
                                   MachineBasicBlock &MBB) const {
  SIMachineFunctionInfo *FuncInfo = MF.getInfo<SIMachineFunctionInfo>();
  if (FuncInfo->isEntryFunction()) {
    emitEntryFunctionPrologue(MF, MBB);
    return;
  }

  const MachineFrameInfo &MFI = MF.getFrameInfo();
  MachineRegisterInfo &MRI = MF.getRegInfo();
  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIInstrInfo *TII = ST.getInstrInfo();
  const SIRegisterInfo &TRI = TII->getRegisterInfo();
  const MCRegisterInfo *MCRI = MF.getMMI().getContext().getRegisterInfo();

  unsigned StackPtrReg = FuncInfo->getStackPtrOffsetReg();
  unsigned FramePtrReg = FuncInfo->getFrameOffsetReg();
  LivePhysRegs LiveRegs;

  MachineBasicBlock::iterator MBBI = MBB.begin();
  DebugLoc DL;

  bool HasFP = false;
  uint32_t NumBytes = MFI.getStackSize();
  uint32_t RoundedSize = NumBytes;
  // To avoid clobbering VGPRs in lanes that weren't active on function entry,
  // turn on all lanes before doing the spill to memory.
  unsigned ScratchExecCopy = AMDGPU::NoRegister;

  emitPrologueEntryCFI(MBB, MBBI, DL);

  // Emit the copy if we need an FP, and are using a free SGPR to save it.
  if (FuncInfo->SGPRForFPSaveRestoreCopy != AMDGPU::NoRegister) {
    BuildMI(MBB, MBBI, DL, TII->get(AMDGPU::COPY), FuncInfo->SGPRForFPSaveRestoreCopy)
      .addReg(FramePtrReg)
      .setMIFlag(MachineInstr::FrameSetup);
    buildCFI(
        MBB, MBBI, DL,
        MCCFIInstruction::createRegister(
            nullptr, MCRI->getDwarfRegNum(FramePtrReg, false),
            MCRI->getDwarfRegNum(FuncInfo->SGPRForFPSaveRestoreCopy, false)));
  }

  if (TRI.isCFISavedRegsSpillEnabled()) {
    MCRegister ReturnAddressReg = TRI.getReturnAddressReg(MF);
    ArrayRef<SIMachineFunctionInfo::SpilledReg> ReturnAddressSpill =
        FuncInfo->getSGPRToVGPRSpills(FuncInfo->ReturnAddressSaveIndex);
    assert(ReturnAddressSpill.size() == 2);
    BuildMI(MBB, MBBI, DL, TII->getMCOpcodeFromPseudo(AMDGPU::V_WRITELANE_B32),
            ReturnAddressSpill[0].VGPR)
        .addReg(TRI.getSubReg(ReturnAddressReg, TRI.getSubRegFromChannel(0)))
        .addImm(ReturnAddressSpill[0].Lane)
        .addReg(ReturnAddressSpill[0].VGPR, RegState::Undef);
    BuildMI(MBB, MBBI, DL, TII->getMCOpcodeFromPseudo(AMDGPU::V_WRITELANE_B32),
            ReturnAddressSpill[1].VGPR)
        .addReg(TRI.getSubReg(ReturnAddressReg, TRI.getSubRegFromChannel(1)))
        .addImm(ReturnAddressSpill[1].Lane)
        .addReg(ReturnAddressSpill[1].VGPR, RegState::Undef);
    buildCFIForSGPRToVGPRSpill(MBB, MBBI, DL, AMDGPU::PC_REG,
                               ReturnAddressSpill);

    ArrayRef<SIMachineFunctionInfo::SpilledReg> EXECSpill =
        FuncInfo->getSGPRToVGPRSpills(FuncInfo->EXECSaveIndex);
    assert(EXECSpill.size());
    BuildMI(MBB, MBBI, DL, TII->getMCOpcodeFromPseudo(AMDGPU::V_WRITELANE_B32),
            EXECSpill[0].VGPR)
        .addReg(AMDGPU::EXEC_LO)
        .addImm(EXECSpill[0].Lane)
        .addReg(EXECSpill[0].VGPR, RegState::Undef);
    if (!ST.isWave32()) {
      assert(EXECSpill.size() == 2);
      BuildMI(MBB, MBBI, DL,
              TII->getMCOpcodeFromPseudo(AMDGPU::V_WRITELANE_B32),
              EXECSpill[1].VGPR)
          .addReg(AMDGPU::EXEC_HI)
          .addImm(EXECSpill[1].Lane)
          .addReg(EXECSpill[1].VGPR, RegState::Undef);
    }
    buildCFIForSGPRToVGPRSpill(MBB, MBBI, DL, AMDGPU::EXEC, EXECSpill);
  }

  for (const SIMachineFunctionInfo::SGPRSpillVGPRCSR &Reg
         : FuncInfo->getSGPRSpillVGPRs()) {
    if (!Reg.FI.hasValue())
      continue;

    if (ScratchExecCopy == AMDGPU::NoRegister) {
      if (LiveRegs.empty()) {
        LiveRegs.init(TRI);
        LiveRegs.addLiveIns(MBB);
        if (FuncInfo->SGPRForFPSaveRestoreCopy)
          LiveRegs.removeReg(FuncInfo->SGPRForFPSaveRestoreCopy);
      }

      ScratchExecCopy
        = findScratchNonCalleeSaveRegister(MRI, LiveRegs,
                                           *TRI.getWaveMaskRegClass());
      assert(FuncInfo->SGPRForFPSaveRestoreCopy != ScratchExecCopy);

      const unsigned OrSaveExec = ST.isWave32() ?
        AMDGPU::S_OR_SAVEEXEC_B32 : AMDGPU::S_OR_SAVEEXEC_B64;
      BuildMI(MBB, MBBI, DL, TII->get(OrSaveExec),
              ScratchExecCopy)
        .addImm(-1);
    }

    int FI = Reg.FI.getValue();

    buildPrologSpill(LiveRegs, MBB, MBBI, TII, Reg.VGPR,
                     FuncInfo->getScratchRSrcReg(), StackPtrReg, FI);

    // We spill the entire VGPR, so we can get away with just cfi_offset
    buildCFI(MBB, MBBI, DL,
             MCCFIInstruction::createOffset(
                 nullptr, MCRI->getDwarfRegNum(Reg.VGPR, false),
                 MFI.getObjectOffset(FI) * ST.getWavefrontSize()));
  }

  if (ScratchExecCopy != AMDGPU::NoRegister) {
    // FIXME: Split block and make terminator.
    unsigned ExecMov = ST.isWave32() ? AMDGPU::S_MOV_B32 : AMDGPU::S_MOV_B64;
    unsigned Exec = ST.isWave32() ? AMDGPU::EXEC_LO : AMDGPU::EXEC;
    BuildMI(MBB, MBBI, DL, TII->get(ExecMov), Exec)
      .addReg(ScratchExecCopy, RegState::Kill);
    LiveRegs.addReg(ScratchExecCopy);
  }


  if (FuncInfo->FramePointerSaveIndex) {
    const int FI = FuncInfo->FramePointerSaveIndex.getValue();
    assert(!MFI.isDeadObjectIndex(FI) &&
           MFI.getStackID(FI) == TargetStackID::SGPRSpill);
    ArrayRef<SIMachineFunctionInfo::SpilledReg> Spill
      = FuncInfo->getSGPRToVGPRSpills(FI);
    assert(Spill.size() == 1);

    // Save FP before setting it up.
    // FIXME: This should respect spillSGPRToVGPR;
    BuildMI(MBB, MBBI, DL, TII->getMCOpcodeFromPseudo(AMDGPU::V_WRITELANE_B32),
            Spill[0].VGPR)
      .addReg(FramePtrReg)
      .addImm(Spill[0].Lane)
      .addReg(Spill[0].VGPR, RegState::Undef);

    buildCFIForSGPRToVGPRSpill(MBB, MBBI, DL, FramePtrReg, Spill[0].VGPR,
                               Spill[0].Lane);
  }

  if (TRI.needsStackRealignment(MF)) {
    HasFP = true;
    const unsigned Alignment = MFI.getMaxAlign().value();

    RoundedSize += Alignment;
    if (LiveRegs.empty()) {
      LiveRegs.init(TRI);
      LiveRegs.addLiveIns(MBB);
      LiveRegs.addReg(FuncInfo->SGPRForFPSaveRestoreCopy);
    }

    unsigned ScratchSPReg = findScratchNonCalleeSaveRegister(
        MRI, LiveRegs, AMDGPU::SReg_32_XM0RegClass);
    assert(ScratchSPReg != AMDGPU::NoRegister &&
           ScratchSPReg != FuncInfo->SGPRForFPSaveRestoreCopy);

    // s_add_u32 tmp_reg, s32, NumBytes
    // s_and_b32 s32, tmp_reg, 0b111...0000
    BuildMI(MBB, MBBI, DL, TII->get(AMDGPU::S_ADD_U32), ScratchSPReg)
      .addReg(StackPtrReg)
      .addImm((Alignment - 1) * ST.getWavefrontSize())
      .setMIFlag(MachineInstr::FrameSetup);
    BuildMI(MBB, MBBI, DL, TII->get(AMDGPU::S_AND_B32), FramePtrReg)
      .addReg(ScratchSPReg, RegState::Kill)
      .addImm(-Alignment * ST.getWavefrontSize())
      .setMIFlag(MachineInstr::FrameSetup);
    FuncInfo->setIsStackRealigned(true);
  } else if ((HasFP = hasFP(MF))) {
    // If we need a base pointer, set it up here. It's whatever the value of
    // the stack pointer is at this point. Any variable size objects will be
    // allocated after this, so we can still use the base pointer to reference
    // locals.
    BuildMI(MBB, MBBI, DL, TII->get(AMDGPU::COPY), FramePtrReg)
      .addReg(StackPtrReg)
      .setMIFlag(MachineInstr::FrameSetup);
  }

  if (HasFP) {
    buildCFI(MBB, MBBI, DL,
             MCCFIInstruction::createDefCfaRegister(
                 nullptr, MCRI->getDwarfRegNum(FramePtrReg, false)));
  }

  if (HasFP && RoundedSize != 0) {
    BuildMI(MBB, MBBI, DL, TII->get(AMDGPU::S_ADD_U32), StackPtrReg)
      .addReg(StackPtrReg)
      .addImm(RoundedSize * ST.getWavefrontSize())
      .setMIFlag(MachineInstr::FrameSetup);
  }

  assert((!HasFP || (FuncInfo->SGPRForFPSaveRestoreCopy != AMDGPU::NoRegister ||
                     FuncInfo->FramePointerSaveIndex)) &&
         "Needed to save FP but didn't save it anywhere");

  assert((HasFP || (FuncInfo->SGPRForFPSaveRestoreCopy == AMDGPU::NoRegister &&
                    !FuncInfo->FramePointerSaveIndex)) &&
         "Saved FP but didn't need it");
}

void SIFrameLowering::emitEpilogue(MachineFunction &MF,
                                   MachineBasicBlock &MBB) const {
  const SIMachineFunctionInfo *FuncInfo = MF.getInfo<SIMachineFunctionInfo>();
  if (FuncInfo->isEntryFunction())
    return;

  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIInstrInfo *TII = ST.getInstrInfo();
  MachineRegisterInfo &MRI = MF.getRegInfo();
  const MCRegisterInfo *MCRI = MF.getMMI().getContext().getRegisterInfo();
  MachineBasicBlock::iterator MBBI = MBB.getFirstTerminator();
  LivePhysRegs LiveRegs;
  DebugLoc DL;

  const MachineFrameInfo &MFI = MF.getFrameInfo();
  uint32_t NumBytes = MFI.getStackSize();
  uint32_t RoundedSize = FuncInfo->isStackRealigned()
                             ? NumBytes + MFI.getMaxAlign().value()
                             : NumBytes;
  const Register StackPtrReg = FuncInfo->getStackPtrOffsetReg();
  const Register FramePtrReg = FuncInfo->getFrameOffsetReg();

  if (RoundedSize != 0 && hasFP(MF)) {
    const unsigned StackPtrReg = FuncInfo->getStackPtrOffsetReg();
    BuildMI(MBB, MBBI, DL, TII->get(AMDGPU::S_SUB_U32), StackPtrReg)
      .addReg(StackPtrReg)
      .addImm(RoundedSize * ST.getWavefrontSize())
      .setMIFlag(MachineInstr::FrameDestroy);
  }

  if (FuncInfo->SGPRForFPSaveRestoreCopy != AMDGPU::NoRegister) {
    BuildMI(MBB, MBBI, DL, TII->get(AMDGPU::COPY), FramePtrReg)
        .addReg(FuncInfo->SGPRForFPSaveRestoreCopy)
        .setMIFlag(MachineInstr::FrameSetup);
  }

  if (FuncInfo->FramePointerSaveIndex) {
    const int FI = FuncInfo->FramePointerSaveIndex.getValue();

    assert(!MF.getFrameInfo().isDeadObjectIndex(FI) &&
           MF.getFrameInfo().getStackID(FI) == TargetStackID::SGPRSpill);

    ArrayRef<SIMachineFunctionInfo::SpilledReg> Spill
      = FuncInfo->getSGPRToVGPRSpills(FI);
    assert(Spill.size() == 1);
    BuildMI(MBB, MBBI, DL, TII->getMCOpcodeFromPseudo(AMDGPU::V_READLANE_B32),
            FramePtrReg)
        .addReg(Spill[0].VGPR)
        .addImm(Spill[0].Lane);
  }

  if (hasFP(MF)) {
    buildCFI(MBB, MBBI, DL,
             MCCFIInstruction::createDefCfaRegister(
                 nullptr, MCRI->getDwarfRegNum(StackPtrReg, false)));
  }

  unsigned ScratchExecCopy = AMDGPU::NoRegister;
  for (const SIMachineFunctionInfo::SGPRSpillVGPRCSR &Reg
         : FuncInfo->getSGPRSpillVGPRs()) {
    if (!Reg.FI.hasValue())
      continue;

    const SIRegisterInfo &TRI = TII->getRegisterInfo();
    if (ScratchExecCopy == AMDGPU::NoRegister) {
      // See emitPrologue
      if (LiveRegs.empty()) {
        LiveRegs.init(*ST.getRegisterInfo());
        LiveRegs.addLiveOuts(MBB);
        LiveRegs.stepBackward(*MBBI);
      }

      ScratchExecCopy = findScratchNonCalleeSaveRegister(
          MRI, LiveRegs, *TRI.getWaveMaskRegClass());
      LiveRegs.removeReg(ScratchExecCopy);

      const unsigned OrSaveExec =
          ST.isWave32() ? AMDGPU::S_OR_SAVEEXEC_B32 : AMDGPU::S_OR_SAVEEXEC_B64;

      BuildMI(MBB, MBBI, DL, TII->get(OrSaveExec), ScratchExecCopy)
        .addImm(-1);
    }

    buildEpilogReload(LiveRegs, MBB, MBBI, TII, Reg.VGPR,
                      FuncInfo->getScratchRSrcReg(),
                      FuncInfo->getStackPtrOffsetReg(), Reg.FI.getValue());
  }

  if (ScratchExecCopy != AMDGPU::NoRegister) {
    // FIXME: Split block and make terminator.
    unsigned ExecMov = ST.isWave32() ? AMDGPU::S_MOV_B32 : AMDGPU::S_MOV_B64;
    MCRegister Exec = ST.isWave32() ? AMDGPU::EXEC_LO : AMDGPU::EXEC;
    BuildMI(MBB, MBBI, DL, TII->get(ExecMov), Exec)
      .addReg(ScratchExecCopy, RegState::Kill);
  }
}

// Note SGPRSpill stack IDs should only be used for SGPR spilling to VGPRs, not
// memory. They should have been removed by now.
static bool allStackObjectsAreDead(const MachineFrameInfo &MFI) {
  for (int I = MFI.getObjectIndexBegin(), E = MFI.getObjectIndexEnd();
       I != E; ++I) {
    if (!MFI.isDeadObjectIndex(I))
      return false;
  }

  return true;
}

#ifndef NDEBUG
static bool allSGPRSpillsAreDead(const MachineFrameInfo &MFI,
                                 Optional<int> FramePointerSaveIndex) {
  for (int I = MFI.getObjectIndexBegin(), E = MFI.getObjectIndexEnd();
       I != E; ++I) {
    if (!MFI.isDeadObjectIndex(I) &&
        MFI.getStackID(I) == TargetStackID::SGPRSpill &&
        FramePointerSaveIndex && I != FramePointerSaveIndex) {
      return false;
    }
  }

  return true;
}
#endif

int SIFrameLowering::getFrameIndexReference(const MachineFunction &MF, int FI,
                                            Register &FrameReg) const {
  const SIRegisterInfo *RI = MF.getSubtarget<GCNSubtarget>().getRegisterInfo();

  FrameReg = RI->getFrameRegister(MF);
  return MF.getFrameInfo().getObjectOffset(FI);
}

void SIFrameLowering::processFunctionBeforeFrameFinalized(
  MachineFunction &MF,
  RegScavenger *RS) const {
  MachineFrameInfo &MFI = MF.getFrameInfo();

  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIRegisterInfo *TRI = ST.getRegisterInfo();
  SIMachineFunctionInfo *FuncInfo = MF.getInfo<SIMachineFunctionInfo>();

  FuncInfo->removeDeadFrameIndices(MFI);
  assert(allSGPRSpillsAreDead(MFI, None) &&
         "SGPR spill should have been removed in SILowerSGPRSpills");

  // FIXME: The other checks should be redundant with allStackObjectsAreDead,
  // but currently hasNonSpillStackObjects is set only from source
  // allocas. Stack temps produced from legalization are not counted currently.
  if (!allStackObjectsAreDead(MFI)) {
    assert(RS && "RegScavenger required if spilling");

    if (FuncInfo->isEntryFunction()) {
      int ScavengeFI = MFI.CreateFixedObject(
        TRI->getSpillSize(AMDGPU::SGPR_32RegClass), 0, false);
      RS->addScavengingFrameIndex(ScavengeFI);
    } else {
      int ScavengeFI = MFI.CreateStackObject(
        TRI->getSpillSize(AMDGPU::SGPR_32RegClass),
        TRI->getSpillAlignment(AMDGPU::SGPR_32RegClass),
        false);
      RS->addScavengingFrameIndex(ScavengeFI);
    }
  }
}

static void allocateCFISave(MachineFunction &MF, int &FI, Register Reg) {
  SIMachineFunctionInfo *MFI = MF.getInfo<SIMachineFunctionInfo>();
  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIRegisterInfo *TRI = ST.getRegisterInfo();
  const TargetRegisterClass *RC = TRI->getMinimalPhysRegClass(Reg);
  int NewFI = MF.getFrameInfo().CreateStackObject(
      TRI->getSpillSize(*RC), TRI->getSpillAlignment(*RC), true);
  if (!MFI->allocateSGPRSpillToVGPR(MF, NewFI))
    llvm_unreachable("allocate SGPR spill should have worked");
  FI = NewFI;
}

// Only report VGPRs to generic code.
void SIFrameLowering::determineCalleeSaves(MachineFunction &MF,
                                           BitVector &SavedVGPRs,
                                           RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedVGPRs, RS);
  SIMachineFunctionInfo *MFI = MF.getInfo<SIMachineFunctionInfo>();
  if (MFI->isEntryFunction())
    return;

  const MachineFrameInfo &FrameInfo = MF.getFrameInfo();
  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIRegisterInfo *TRI = ST.getRegisterInfo();

  // Ignore the SGPRs the default implementation found.
  SavedVGPRs.clearBitsNotInMask(TRI->getAllVGPRRegMask());

  // hasFP only knows about stack objects that already exist. We're now
  // determining the stack slots that will be created, so we have to predict
  // them. Stack objects force FP usage with calls.
  //
  // Note a new VGPR CSR may be introduced if one is used for the spill, but we
  // don't want to report it here.
  //
  // FIXME: Is this really hasReservedCallFrame?
  const bool WillHaveFP =
      FrameInfo.hasCalls() &&
      (SavedVGPRs.any() || !allStackObjectsAreDead(FrameInfo));

  // VGPRs used for SGPR spilling need to be specially inserted in the prolog,
  // so don't allow the default insertion to handle them.
  for (auto SSpill : MFI->getSGPRSpillVGPRs())
    SavedVGPRs.reset(SSpill.VGPR);

  if (TRI->isCFISavedRegsSpillEnabled()) {
    allocateCFISave(MF, MFI->ReturnAddressSaveIndex,
                    TRI->getReturnAddressReg(MF));
    allocateCFISave(MF, MFI->EXECSaveIndex,
                    ST.isWave32() ? AMDGPU::EXEC_LO : AMDGPU::EXEC);
  }

  const bool HasFP = WillHaveFP || hasFP(MF);
  if (!HasFP)
    return;

  if (MFI->haveFreeLanesForSGPRSpill(MF, 1)) {
    int NewFI = MF.getFrameInfo().CreateStackObject(4, 4, true, nullptr,
                                                    TargetStackID::SGPRSpill);

    // If there is already a VGPR with free lanes, use it. We may already have
    // to pay the penalty for spilling a CSR VGPR.
    if (!MFI->allocateSGPRSpillToVGPR(MF, NewFI))
      llvm_unreachable("allocate SGPR spill should have worked");

    MFI->FramePointerSaveIndex = NewFI;

    LLVM_DEBUG(
      auto Spill = MFI->getSGPRToVGPRSpills(NewFI).front();
      dbgs() << "Spilling FP to  " << printReg(Spill.VGPR, TRI)
             << ':' << Spill.Lane << '\n');
    return;
  }

  MFI->SGPRForFPSaveRestoreCopy = findUnusedSGPRNonCalleeSaved(MF.getRegInfo());

  if (!MFI->SGPRForFPSaveRestoreCopy) {
    // There's no free lane to spill, and no free register to save FP, so we're
    // forced to spill another VGPR to use for the spill.
    int NewFI = MF.getFrameInfo().CreateStackObject(4, 4, true, nullptr,
                                                    TargetStackID::SGPRSpill);
    if (!MFI->allocateSGPRSpillToVGPR(MF, NewFI))
      llvm_unreachable("allocate SGPR spill should have worked");
    MFI->FramePointerSaveIndex = NewFI;

    LLVM_DEBUG(
      auto Spill = MFI->getSGPRToVGPRSpills(NewFI).front();
      dbgs() << "FP requires fallback spill to " << printReg(Spill.VGPR, TRI)
             << ':' << Spill.Lane << '\n';);
  } else {
    LLVM_DEBUG(dbgs() << "Saving FP with copy to " <<
               printReg(MFI->SGPRForFPSaveRestoreCopy, TRI) << '\n');
  }
}

void SIFrameLowering::determineCalleeSavesSGPR(MachineFunction &MF,
                                               BitVector &SavedRegs,
                                               RegScavenger *RS) const {
  TargetFrameLowering::determineCalleeSaves(MF, SavedRegs, RS);
  const SIMachineFunctionInfo *MFI = MF.getInfo<SIMachineFunctionInfo>();
  if (MFI->isEntryFunction())
    return;

  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIRegisterInfo *TRI = ST.getRegisterInfo();

  // The SP is specifically managed and we don't want extra spills of it.
  SavedRegs.reset(MFI->getStackPtrOffsetReg());
  SavedRegs.clearBitsInMask(TRI->getAllVGPRRegMask());
}

bool SIFrameLowering::assignCalleeSavedSpillSlots(
    MachineFunction &MF, const TargetRegisterInfo *TRI,
    std::vector<CalleeSavedInfo> &CSI) const {
  if (CSI.empty())
    return true; // Early exit if no callee saved registers are modified!

  const SIMachineFunctionInfo *FuncInfo = MF.getInfo<SIMachineFunctionInfo>();
  if (!FuncInfo->SGPRForFPSaveRestoreCopy)
    return false;

  for (auto &CS : CSI) {
    if (CS.getReg() == FuncInfo->getFrameOffsetReg()) {
      if (FuncInfo->SGPRForFPSaveRestoreCopy != AMDGPU::NoRegister)
        CS.setDstReg(FuncInfo->SGPRForFPSaveRestoreCopy);
      break;
    }
  }

  return false;
}

MachineBasicBlock::iterator SIFrameLowering::eliminateCallFramePseudoInstr(
  MachineFunction &MF,
  MachineBasicBlock &MBB,
  MachineBasicBlock::iterator I) const {
  int64_t Amount = I->getOperand(0).getImm();
  if (Amount == 0)
    return MBB.erase(I);

  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const SIInstrInfo *TII = ST.getInstrInfo();
  const DebugLoc &DL = I->getDebugLoc();
  unsigned Opc = I->getOpcode();
  bool IsDestroy = Opc == TII->getCallFrameDestroyOpcode();
  uint64_t CalleePopAmount = IsDestroy ? I->getOperand(1).getImm() : 0;

  if (!hasReservedCallFrame(MF)) {
    Amount = alignTo(Amount, getStackAlign());
    assert(isUInt<32>(Amount) && "exceeded stack address space size");
    const SIMachineFunctionInfo *MFI = MF.getInfo<SIMachineFunctionInfo>();
    unsigned SPReg = MFI->getStackPtrOffsetReg();

    unsigned Op = IsDestroy ? AMDGPU::S_SUB_U32 : AMDGPU::S_ADD_U32;
    BuildMI(MBB, I, DL, TII->get(Op), SPReg)
      .addReg(SPReg)
      .addImm(Amount * ST.getWavefrontSize());
  } else if (CalleePopAmount != 0) {
    llvm_unreachable("is this used?");
  }

  return MBB.erase(I);
}

bool SIFrameLowering::spillCalleeSavedRegisters(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    const ArrayRef<CalleeSavedInfo> CSI, const TargetRegisterInfo *TRI) const {
  MachineFunction &MF = *MBB.getParent();
  const SIInstrInfo *TII = MF.getSubtarget<GCNSubtarget>().getInstrInfo();

  for (const CalleeSavedInfo &CS : CSI) {
    // Insert the spill to the stack frame.
    unsigned Reg = CS.getReg();

    if (CS.isSpilledToReg()) {
      BuildMI(MBB, MBBI, DebugLoc(), TII->get(TargetOpcode::COPY),
              CS.getDstReg())
          .addReg(Reg, getKillRegState(true));
    } else {
      const TargetRegisterClass *RC = TRI->getMinimalPhysRegClass(Reg);
      TII->storeRegToStackSlotCFI(MBB, MBBI, Reg, true, CS.getFrameIdx(), RC,
                                  TRI);
    }
  }

  return true;
}

bool SIFrameLowering::hasFP(const MachineFunction &MF) const {
  const MachineFrameInfo &MFI = MF.getFrameInfo();

  // For entry functions we can use an immediate offset in most cases, so the
  // presence of calls doesn't imply we need a distinct frame pointer.
  if (MFI.hasCalls() &&
      !MF.getInfo<SIMachineFunctionInfo>()->isEntryFunction()) {
    // All offsets are unsigned, so need to be addressed in the same direction
    // as stack growth.

    // FIXME: This function is pretty broken, since it can be called before the
    // frame layout is determined or CSR spills are inserted.
    return MFI.getStackSize() != 0;
  }

  return MFI.hasVarSizedObjects() || MFI.isFrameAddressTaken() ||
    MFI.hasStackMap() || MFI.hasPatchPoint() ||
    MF.getSubtarget<GCNSubtarget>().getRegisterInfo()->needsStackRealignment(MF) ||
    MF.getTarget().Options.DisableFramePointerElim(MF);
}

void SIFrameLowering::buildCFI(MachineBasicBlock &MBB,
                               MachineBasicBlock::iterator MBBI,
                               const DebugLoc &DL,
                               const MCCFIInstruction &CFIInst) const {
  MachineFunction &MF = *MBB.getParent();
  const SIInstrInfo *TII = MF.getSubtarget<GCNSubtarget>().getInstrInfo();
  BuildMI(MBB, MBBI, DL, TII->get(TargetOpcode::CFI_INSTRUCTION))
      .addCFIIndex(MF.addFrameInst(CFIInst))
      .setMIFlag(MachineInstr::FrameSetup);
}

static void encodeDwarfRegisterLocation(int DwarfReg, raw_ostream &OS) {
  if (DwarfReg < 32) {
    OS << uint8_t(dwarf::DW_OP_reg0 + DwarfReg);
  } else {
    OS << uint8_t(dwarf::DW_OP_regx);
    encodeULEB128(DwarfReg, OS);
  }
}

void SIFrameLowering::buildCFIForSGPRToVGPRSpill(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    const DebugLoc &DL, const Register SGPR, const Register VGPR,
    const int Lane) const {
  MachineFunction &MF = *MBB.getParent();
  const MCRegisterInfo &MCRI = *MF.getMMI().getContext().getRegisterInfo();
  int DwarfSGPR = MCRI.getDwarfRegNum(SGPR, false);
  int DwarfVGPR = MCRI.getDwarfRegNum(VGPR, false);

  // CFI for an SGPR spilled to a single lane of a VGPR is implemented as an
  // expression(E) rule where E is a register location description referencing
  // a VGPR register location storage at a byte offset of the lane index
  // multiplied by the size of an SGPR (4 bytes). In other words we generate
  // the following DWARF:
  //
  // DW_CFA_expression: <SGPR>,
  //    (DW_OP_regx <VGPR>) (DW_OP_LLVM_offset_uconst <Lane>*4)
  //
  // The memory location description for the current CFA is pushed on the
  // stack before E is evaluated, but we choose not to drop it as it would
  // require a longer expression E and DWARF defines the result of the
  // evaulation to be the location description on the top of the stack (i.e. the
  // implictly pushed one is just ignored.)
  SmallString<20> CFIInst;
  raw_svector_ostream OSCFIInst(CFIInst);
  SmallString<20> Block;
  raw_svector_ostream OSBlock(Block);

  OSCFIInst << uint8_t(dwarf::DW_CFA_expression);
  encodeULEB128(DwarfSGPR, OSCFIInst);

  encodeDwarfRegisterLocation(DwarfVGPR, OSBlock);
  OSBlock << uint8_t(dwarf::DW_OP_LLVM_offset_uconst);
  // FIXME:
  const unsigned SGPRByteSize = 4;
  encodeULEB128(Lane * SGPRByteSize, OSBlock);

  encodeULEB128(Block.size(), OSCFIInst);
  OSCFIInst << Block;

  buildCFI(MBB, MBBI, DL,
           MCCFIInstruction::createEscape(nullptr, OSCFIInst.str()));
}

void SIFrameLowering::buildCFIForSGPRToVGPRSpill(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    const DebugLoc &DL, Register SGPR,
    ArrayRef<SIMachineFunctionInfo::SpilledReg> VGPRSpills) const {
  MachineFunction &MF = *MBB.getParent();
  const MCRegisterInfo &MCRI = *MF.getMMI().getContext().getRegisterInfo();
  int DwarfSGPR = MCRI.getDwarfRegNum(SGPR, false);

  // CFI for an SGPR spilled to a multiple lanes of VGPRs is implemented as an
  // expression(E) rule where E is a composite location description
  // with multiple parts each referencing
  // VGPR register location storage with a bit offset of the lane index
  // multiplied by the size of an SGPR (32 bits). In other words we generate
  // the following DWARF:
  //
  // DW_CFA_expression: <SGPR>,
  //    (DW_OP_regx <VGPR[0]>) (DW_OP_bit_piece 32, <Lane[0]>*32)
  //    (DW_OP_regx <VGPR[1]>) (DW_OP_bit_piece 32, <Lane[1]>*32)
  //    ...
  //    (DW_OP_regx <VGPR[N]>) (DW_OP_bit_piece 32, <Lane[N]>*32)
  //
  // The memory location description for the current CFA is pushed on the
  // stack before E is evaluated, but we choose not to drop it as it would
  // require a longer expression E and DWARF defines the result of the
  // evaulation to be the location description on the top of the stack (i.e. the
  // implictly pushed one is just ignored.)
  SmallString<20> CFIInst;
  raw_svector_ostream OSCFIInst(CFIInst);
  SmallString<20> Block;
  raw_svector_ostream OSBlock(Block);

  OSCFIInst << uint8_t(dwarf::DW_CFA_expression);
  encodeULEB128(DwarfSGPR, OSCFIInst);

  // TODO: Detect when we can merge multiple adjacent pieces, or even reduce
  // this to a register location description (when all pieces are adjacent).
  for (SIMachineFunctionInfo::SpilledReg Spill : VGPRSpills) {
    encodeDwarfRegisterLocation(MCRI.getDwarfRegNum(Spill.VGPR, false),
                                OSBlock);
    OSBlock << uint8_t(dwarf::DW_OP_bit_piece);
    // FIXME:
    const unsigned SGPRBitSize = 32;
    encodeULEB128(SGPRBitSize, OSBlock);
    encodeULEB128(SGPRBitSize * Spill.Lane, OSBlock);
  }

  encodeULEB128(Block.size(), OSCFIInst);
  OSCFIInst << Block;

  buildCFI(MBB, MBBI, DL,
           MCCFIInstruction::createEscape(nullptr, OSCFIInst.str()));
}

void SIFrameLowering::buildCFIForVGPRToVMEMSpill(
    MachineBasicBlock &MBB, MachineBasicBlock::iterator MBBI,
    const DebugLoc &DL, unsigned VGPR, int64_t Offset) const {
  MachineFunction &MF = *MBB.getParent();
  const GCNSubtarget &ST = MF.getSubtarget<GCNSubtarget>();
  const MCRegisterInfo &MCRI = *MF.getMMI().getContext().getRegisterInfo();
  int DwarfVGPR = MCRI.getDwarfRegNum(VGPR, false);

  SmallString<20> CFIInst;
  raw_svector_ostream OSCFIInst(CFIInst);
  SmallString<20> Block;
  raw_svector_ostream OSBlock(Block);

  OSCFIInst << uint8_t(dwarf::DW_CFA_expression);
  encodeULEB128(DwarfVGPR, OSCFIInst);

  encodeDwarfRegisterLocation(DwarfVGPR, OSBlock);
  OSBlock << uint8_t(dwarf::DW_OP_swap);
  OSBlock << uint8_t(dwarf::DW_OP_LLVM_offset_uconst);
  encodeULEB128(Offset, OSBlock);
  OSBlock << uint8_t(dwarf::DW_OP_LLVM_call_frame_entry_reg);
  encodeULEB128(MCRI.getDwarfRegNum(
                    ST.isWave32() ? AMDGPU::EXEC_LO : AMDGPU::EXEC, false),
                OSBlock);
  OSBlock << uint8_t(dwarf::DW_OP_deref_size);
  OSBlock << uint8_t(ST.getWavefrontSize() / CHAR_BIT);
  OSBlock << uint8_t(dwarf::DW_OP_LLVM_select_bit_piece);
  // FIXME:
  const unsigned VGPRLaneBitSize = 32;
  encodeULEB128(VGPRLaneBitSize, OSBlock);
  encodeULEB128(ST.getWavefrontSize(), OSBlock);

  encodeULEB128(Block.size(), OSCFIInst);
  OSCFIInst << Block;

  buildCFI(MBB, MBBI, DL,
           MCCFIInstruction::createEscape(nullptr, OSCFIInst.str()));
}
