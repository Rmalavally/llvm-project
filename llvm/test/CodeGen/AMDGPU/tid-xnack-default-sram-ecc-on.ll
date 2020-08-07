; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx900 -mattr=+sram-ecc --amdgcn-new-target-id < %s | FileCheck --check-prefixes=ASM %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx900 -mattr=+sram-ecc --amdgcn-new-target-id -filetype=obj < %s | llvm-readobj --file-headers - | FileCheck --check-prefixes=ELF %s

; ASM: .amdgcn_target "amdgcn-amd-amdhsa--gfx900:sram-ecc+"
; ASM: amdhsa.target: 'amdgcn-amd-amdhsa--gfx900:sram-ecc+'
; ELF: Flags [ (0xD2C)
; ELF:   EF_AMDGPU_FEATURE_SRAM_ECC_ON (0xC00)
; ELF:   EF_AMDGPU_FEATURE_XNACK_DEFAULT (0x100)
; ELF:   EF_AMDGPU_MACH_AMDGCN_GFX900 (0x2C)
; ELF: ]

define amdgpu_kernel void @empty() {
entry:
  ret void
}

!0 = !{ i32 8, !"target-id", !"amdgcn-amd-amdhsa--gfx900:sram-ecc+" }
!llvm.module.flags = !{ !0 }
