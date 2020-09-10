; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -march=amdgcn -mcpu=gfx1010 -verify-machineinstrs | FileCheck -check-prefix=GCN %s

; FIXME: The MUBUF loads in this test output are incorrect, their SOffset
; should use the frame offset register, not the ABI stack pointer register. We
; rely on the frame index argument of MUBUF stack accesses to survive until PEI
; so we can fix up the SOffset to use the correct frame register in
; eliminateFrameIndex. Some things like LocalStackSlotAllocation can lift the
; frame index up into something (e.g. `v_add_nc_u32`) that we cannot fold back
; into the MUBUF instruction, and so we end up emitting an incorrect offset.
; Fixing this may involve adding stack access pseudos so that we don't have to
; speculatively refer to the ABI stack pointer register at all.

; An assert was hit when frame offset register was used to address FrameIndex.
define amdgpu_kernel void @kernel_background_evaluate(float addrspace(5)* %kg, <4 x i32> addrspace(1)* %input, <4 x float> addrspace(1)* %output, i32 %i) {
; GCN-LABEL: kernel_background_evaluate:
; GCN:       ; %bb.0: ; %entry
; GCN-NEXT:    s_load_dword s0, s[0:1], 0x24
; GCN-NEXT:    s_mov_b32 s36, SCRATCH_RSRC_DWORD0
; GCN-NEXT:    s_mov_b32 s37, SCRATCH_RSRC_DWORD1
; GCN-NEXT:    s_mov_b32 s38, -1
; GCN-NEXT:    s_mov_b32 s39, 0x31c16000
; GCN-NEXT:    s_add_u32 s36, s36, s3
; GCN-NEXT:    s_addc_u32 s37, s37, 0
; GCN-NEXT:    v_mov_b32_e32 v1, 0x2000
; GCN-NEXT:    v_mov_b32_e32 v2, 0x4000
; GCN-NEXT:    v_mov_b32_e32 v3, 0
; GCN-NEXT:    v_mov_b32_e32 v4, 0x400000
; GCN-NEXT:    s_mov_b32 s32, 0xc0000
; GCN-NEXT:    v_add_nc_u32_e64 v40, 4, 0x4000
; GCN-NEXT:    ; implicit-def: $vcc_hi
; GCN-NEXT:    s_getpc_b64 s[4:5]
; GCN-NEXT:    s_add_u32 s4, s4, svm_eval_nodes@rel32@lo+4
; GCN-NEXT:    s_addc_u32 s5, s5, svm_eval_nodes@rel32@hi+4
; GCN-NEXT:    s_waitcnt lgkmcnt(0)
; GCN-NEXT:    v_mov_b32_e32 v0, s0
; GCN-NEXT:    s_mov_b64 s[0:1], s[36:37]
; GCN-NEXT:    s_mov_b64 s[2:3], s[38:39]
; GCN-NEXT:    s_swappc_b64 s[30:31], s[4:5]
; GCN-NEXT:    v_cmp_ne_u32_e32 vcc_lo, 0, v0
; GCN-NEXT:    s_and_saveexec_b32 s0, vcc_lo
; GCN-NEXT:    s_cbranch_execz BB0_2
; GCN-NEXT:  ; %bb.1: ; %if.then4.i
; GCN-NEXT:    s_clause 0x1
; GCN-NEXT:    buffer_load_dword v0, v40, s[36:39], 0 offen
; GCN-NEXT:    buffer_load_dword v1, v40, s[36:39], 0 offen offset:4
; GCN-NEXT:    s_waitcnt vmcnt(0)
; GCN-NEXT:    v_add_nc_u32_e32 v0, v1, v0
; GCN-NEXT:    v_mul_lo_u32 v0, 0x41c64e6d, v0
; GCN-NEXT:    v_add_nc_u32_e32 v0, 0x3039, v0
; GCN-NEXT:    buffer_store_dword v0, v0, s[36:39], 0 offen
; GCN-NEXT:  BB0_2: ; %shader_eval_surface.exit
; GCN-NEXT:    s_endpgm
entry:
  %sd = alloca < 1339 x i32>, align 8192, addrspace(5)
  %state = alloca <4 x i32>, align 16, addrspace(5)
  %rslt = call i32 @svm_eval_nodes(float addrspace(5)* %kg, <1339 x i32> addrspace(5)* %sd, <4 x i32> addrspace(5)* %state, i32 0, i32 4194304)
  %cmp = icmp eq i32 %rslt, 0
  br i1 %cmp, label %shader_eval_surface.exit, label %if.then4.i

if.then4.i:                                       ; preds = %entry
  %rng_hash.i.i = getelementptr inbounds < 4 x i32>, <4 x i32> addrspace(5)* %state, i32 0, i32 1
  %tmp0 = load i32, i32 addrspace(5)* %rng_hash.i.i, align 4
  %rng_offset.i.i = getelementptr inbounds <4 x i32>, <4 x i32> addrspace(5)* %state, i32 0, i32 2
  %tmp1 = load i32, i32 addrspace(5)* %rng_offset.i.i, align 4
  %add.i.i = add i32 %tmp1, %tmp0
  %add1.i.i = add i32 %add.i.i, 0
  %mul.i.i.i.i = mul i32 %add1.i.i, 1103515245
  %add.i.i.i.i = add i32 %mul.i.i.i.i, 12345
  store i32 %add.i.i.i.i, i32 addrspace(5)* undef, align 16
  br label %shader_eval_surface.exit

shader_eval_surface.exit:                         ; preds = %entry
  ret void
}

declare hidden i32 @svm_eval_nodes(float addrspace(5)*, <1339 x i32> addrspace(5)*, <4 x i32> addrspace(5)*, i32, i32) local_unnamed_addr
