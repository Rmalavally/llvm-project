; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -global-isel -mtriple=amdgcn-amd-amdpal -mcpu=gfx900 -verify-machineinstrs < %s | FileCheck -check-prefixes=GCN,GFX9 %s
; RUN: llc -global-isel -mtriple=amdgcn-amd-amdpal -mcpu=hawaii -verify-machineinstrs < %s | FileCheck -check-prefixes=GCN,GFX7 %s

; FIXME:
; XUN: llc -global-isel -mtriple=amdgcn-amd-amdpal -mcpu=tahiti -verify-machineinstrs < %s | FileCheck -check-prefixes=GCN,GFX6 %s

define amdgpu_kernel void @store_lds_v4i32(<4 x i32> addrspace(3)* %out, <4 x i32> %x) {
; GFX9-LABEL: store_lds_v4i32:
; GFX9:       ; %bb.0:
; GFX9-NEXT:    s_load_dword s2, s[0:1], 0x24
; GFX9-NEXT:    s_load_dwordx4 s[4:7], s[0:1], 0x34
; GFX9-NEXT:    s_waitcnt lgkmcnt(0)
; GFX9-NEXT:    v_mov_b32_e32 v4, s2
; GFX9-NEXT:    v_mov_b32_e32 v0, s4
; GFX9-NEXT:    v_mov_b32_e32 v1, s5
; GFX9-NEXT:    v_mov_b32_e32 v2, s6
; GFX9-NEXT:    v_mov_b32_e32 v3, s7
; GFX9-NEXT:    ds_write_b128 v4, v[0:3]
; GFX9-NEXT:    s_endpgm
;
; GFX7-LABEL: store_lds_v4i32:
; GFX7:       ; %bb.0:
; GFX7-NEXT:    s_load_dword s4, s[0:1], 0x9
; GFX7-NEXT:    s_load_dwordx4 s[0:3], s[0:1], 0xd
; GFX7-NEXT:    s_mov_b32 m0, -1
; GFX7-NEXT:    s_waitcnt lgkmcnt(0)
; GFX7-NEXT:    v_mov_b32_e32 v4, s4
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    v_mov_b32_e32 v1, s1
; GFX7-NEXT:    v_mov_b32_e32 v2, s2
; GFX7-NEXT:    v_mov_b32_e32 v3, s3
; GFX7-NEXT:    ds_write_b128 v4, v[0:3]
; GFX7-NEXT:    s_endpgm
  store <4 x i32> %x, <4 x i32> addrspace(3)* %out
  ret void
}

define amdgpu_kernel void @store_lds_v4i32_align1(<4 x i32> addrspace(3)* %out, <4 x i32> %x) {
; GFX9-LABEL: store_lds_v4i32_align1:
; GFX9:       ; %bb.0:
; GFX9-NEXT:    s_load_dword s2, s[0:1], 0x24
; GFX9-NEXT:    s_load_dwordx4 s[4:7], s[0:1], 0x34
; GFX9-NEXT:    s_waitcnt lgkmcnt(0)
; GFX9-NEXT:    v_mov_b32_e32 v1, s2
; GFX9-NEXT:    v_mov_b32_e32 v0, s4
; GFX9-NEXT:    s_lshr_b32 s0, s4, 8
; GFX9-NEXT:    ds_write_b8 v1, v0
; GFX9-NEXT:    v_mov_b32_e32 v0, s0
; GFX9-NEXT:    s_lshr_b32 s1, s4, 16
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:1
; GFX9-NEXT:    v_mov_b32_e32 v0, s1
; GFX9-NEXT:    s_lshr_b32 s3, s4, 24
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:2
; GFX9-NEXT:    v_mov_b32_e32 v0, s3
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:3
; GFX9-NEXT:    v_mov_b32_e32 v0, s5
; GFX9-NEXT:    s_lshr_b32 s0, s5, 8
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:4
; GFX9-NEXT:    v_mov_b32_e32 v0, s0
; GFX9-NEXT:    s_lshr_b32 s1, s5, 16
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:5
; GFX9-NEXT:    v_mov_b32_e32 v0, s1
; GFX9-NEXT:    s_lshr_b32 s2, s5, 24
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:6
; GFX9-NEXT:    v_mov_b32_e32 v0, s2
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:7
; GFX9-NEXT:    v_mov_b32_e32 v0, s6
; GFX9-NEXT:    s_lshr_b32 s0, s6, 8
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:8
; GFX9-NEXT:    v_mov_b32_e32 v0, s0
; GFX9-NEXT:    s_lshr_b32 s1, s6, 16
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:9
; GFX9-NEXT:    v_mov_b32_e32 v0, s1
; GFX9-NEXT:    s_lshr_b32 s2, s6, 24
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:10
; GFX9-NEXT:    v_mov_b32_e32 v0, s2
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:11
; GFX9-NEXT:    v_mov_b32_e32 v0, s7
; GFX9-NEXT:    s_lshr_b32 s0, s7, 8
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:12
; GFX9-NEXT:    v_mov_b32_e32 v0, s0
; GFX9-NEXT:    s_lshr_b32 s1, s7, 16
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:13
; GFX9-NEXT:    v_mov_b32_e32 v0, s1
; GFX9-NEXT:    s_lshr_b32 s2, s7, 24
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:14
; GFX9-NEXT:    v_mov_b32_e32 v0, s2
; GFX9-NEXT:    ds_write_b8 v1, v0 offset:15
; GFX9-NEXT:    s_endpgm
;
; GFX7-LABEL: store_lds_v4i32_align1:
; GFX7:       ; %bb.0:
; GFX7-NEXT:    s_load_dword s4, s[0:1], 0x9
; GFX7-NEXT:    s_load_dwordx4 s[0:3], s[0:1], 0xd
; GFX7-NEXT:    s_mov_b32 m0, -1
; GFX7-NEXT:    s_waitcnt lgkmcnt(0)
; GFX7-NEXT:    v_mov_b32_e32 v1, s4
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    s_lshr_b32 s5, s0, 8
; GFX7-NEXT:    ds_write_b8 v1, v0
; GFX7-NEXT:    v_mov_b32_e32 v0, s5
; GFX7-NEXT:    s_lshr_b32 s6, s0, 16
; GFX7-NEXT:    s_lshr_b32 s7, s0, 24
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:1
; GFX7-NEXT:    v_mov_b32_e32 v0, s6
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:2
; GFX7-NEXT:    v_mov_b32_e32 v0, s7
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:3
; GFX7-NEXT:    v_mov_b32_e32 v0, s1
; GFX7-NEXT:    s_lshr_b32 s0, s1, 8
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:4
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    s_lshr_b32 s4, s1, 16
; GFX7-NEXT:    s_lshr_b32 s5, s1, 24
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:5
; GFX7-NEXT:    v_mov_b32_e32 v0, s4
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:6
; GFX7-NEXT:    v_mov_b32_e32 v0, s5
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:7
; GFX7-NEXT:    v_mov_b32_e32 v0, s2
; GFX7-NEXT:    s_lshr_b32 s0, s2, 8
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:8
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    s_lshr_b32 s1, s2, 16
; GFX7-NEXT:    s_lshr_b32 s4, s2, 24
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:9
; GFX7-NEXT:    v_mov_b32_e32 v0, s1
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:10
; GFX7-NEXT:    v_mov_b32_e32 v0, s4
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:11
; GFX7-NEXT:    v_mov_b32_e32 v0, s3
; GFX7-NEXT:    s_lshr_b32 s0, s3, 8
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:12
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    s_lshr_b32 s1, s3, 16
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:13
; GFX7-NEXT:    v_mov_b32_e32 v0, s1
; GFX7-NEXT:    s_lshr_b32 s2, s3, 24
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:14
; GFX7-NEXT:    v_mov_b32_e32 v0, s2
; GFX7-NEXT:    ds_write_b8 v1, v0 offset:15
; GFX7-NEXT:    s_endpgm
  store <4 x i32> %x, <4 x i32> addrspace(3)* %out, align 1
  ret void
}

define amdgpu_kernel void @store_lds_v4i32_align2(<4 x i32> addrspace(3)* %out, <4 x i32> %x) {
; GFX9-LABEL: store_lds_v4i32_align2:
; GFX9:       ; %bb.0:
; GFX9-NEXT:    s_load_dword s2, s[0:1], 0x24
; GFX9-NEXT:    s_load_dwordx4 s[4:7], s[0:1], 0x34
; GFX9-NEXT:    s_waitcnt lgkmcnt(0)
; GFX9-NEXT:    v_mov_b32_e32 v1, s2
; GFX9-NEXT:    v_mov_b32_e32 v0, s4
; GFX9-NEXT:    s_lshr_b32 s0, s4, 16
; GFX9-NEXT:    ds_write_b16 v1, v0
; GFX9-NEXT:    v_mov_b32_e32 v0, s0
; GFX9-NEXT:    ds_write_b16 v1, v0 offset:2
; GFX9-NEXT:    v_mov_b32_e32 v0, s5
; GFX9-NEXT:    s_lshr_b32 s0, s5, 16
; GFX9-NEXT:    ds_write_b16 v1, v0 offset:4
; GFX9-NEXT:    v_mov_b32_e32 v0, s0
; GFX9-NEXT:    ds_write_b16 v1, v0 offset:6
; GFX9-NEXT:    v_mov_b32_e32 v0, s6
; GFX9-NEXT:    s_lshr_b32 s0, s6, 16
; GFX9-NEXT:    ds_write_b16 v1, v0 offset:8
; GFX9-NEXT:    v_mov_b32_e32 v0, s0
; GFX9-NEXT:    ds_write_b16 v1, v0 offset:10
; GFX9-NEXT:    v_mov_b32_e32 v0, s7
; GFX9-NEXT:    s_lshr_b32 s0, s7, 16
; GFX9-NEXT:    ds_write_b16 v1, v0 offset:12
; GFX9-NEXT:    v_mov_b32_e32 v0, s0
; GFX9-NEXT:    ds_write_b16 v1, v0 offset:14
; GFX9-NEXT:    s_endpgm
;
; GFX7-LABEL: store_lds_v4i32_align2:
; GFX7:       ; %bb.0:
; GFX7-NEXT:    s_load_dword s4, s[0:1], 0x9
; GFX7-NEXT:    s_load_dwordx4 s[0:3], s[0:1], 0xd
; GFX7-NEXT:    s_mov_b32 m0, -1
; GFX7-NEXT:    s_waitcnt lgkmcnt(0)
; GFX7-NEXT:    v_mov_b32_e32 v1, s4
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    s_lshr_b32 s5, s0, 16
; GFX7-NEXT:    ds_write_b16 v1, v0
; GFX7-NEXT:    v_mov_b32_e32 v0, s5
; GFX7-NEXT:    ds_write_b16 v1, v0 offset:2
; GFX7-NEXT:    v_mov_b32_e32 v0, s1
; GFX7-NEXT:    s_lshr_b32 s0, s1, 16
; GFX7-NEXT:    ds_write_b16 v1, v0 offset:4
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    ds_write_b16 v1, v0 offset:6
; GFX7-NEXT:    v_mov_b32_e32 v0, s2
; GFX7-NEXT:    s_lshr_b32 s0, s2, 16
; GFX7-NEXT:    ds_write_b16 v1, v0 offset:8
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    ds_write_b16 v1, v0 offset:10
; GFX7-NEXT:    v_mov_b32_e32 v0, s3
; GFX7-NEXT:    s_lshr_b32 s0, s3, 16
; GFX7-NEXT:    ds_write_b16 v1, v0 offset:12
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    ds_write_b16 v1, v0 offset:14
; GFX7-NEXT:    s_endpgm
  store <4 x i32> %x, <4 x i32> addrspace(3)* %out, align 2
  ret void
}

define amdgpu_kernel void @store_lds_v4i32_align4(<4 x i32> addrspace(3)* %out, <4 x i32> %x) {
; GFX9-LABEL: store_lds_v4i32_align4:
; GFX9:       ; %bb.0:
; GFX9-NEXT:    s_load_dword s2, s[0:1], 0x24
; GFX9-NEXT:    s_load_dwordx4 s[4:7], s[0:1], 0x34
; GFX9-NEXT:    s_waitcnt lgkmcnt(0)
; GFX9-NEXT:    v_mov_b32_e32 v1, s2
; GFX9-NEXT:    v_mov_b32_e32 v0, s4
; GFX9-NEXT:    v_mov_b32_e32 v2, s5
; GFX9-NEXT:    ds_write2_b32 v1, v0, v2 offset1:1
; GFX9-NEXT:    v_mov_b32_e32 v3, s6
; GFX9-NEXT:    v_mov_b32_e32 v0, s7
; GFX9-NEXT:    ds_write2_b32 v1, v3, v0 offset0:2 offset1:3
; GFX9-NEXT:    s_endpgm
;
; GFX7-LABEL: store_lds_v4i32_align4:
; GFX7:       ; %bb.0:
; GFX7-NEXT:    s_load_dword s4, s[0:1], 0x9
; GFX7-NEXT:    s_load_dwordx4 s[0:3], s[0:1], 0xd
; GFX7-NEXT:    s_mov_b32 m0, -1
; GFX7-NEXT:    s_waitcnt lgkmcnt(0)
; GFX7-NEXT:    v_mov_b32_e32 v1, s4
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    v_mov_b32_e32 v2, s1
; GFX7-NEXT:    ds_write2_b32 v1, v0, v2 offset1:1
; GFX7-NEXT:    v_mov_b32_e32 v0, s2
; GFX7-NEXT:    v_mov_b32_e32 v2, s3
; GFX7-NEXT:    ds_write2_b32 v1, v0, v2 offset0:2 offset1:3
; GFX7-NEXT:    s_endpgm
  store <4 x i32> %x, <4 x i32> addrspace(3)* %out, align 4
  ret void
}

define amdgpu_kernel void @store_lds_v4i32_align8(<4 x i32> addrspace(3)* %out, <4 x i32> %x) {
; GFX9-LABEL: store_lds_v4i32_align8:
; GFX9:       ; %bb.0:
; GFX9-NEXT:    s_load_dword s2, s[0:1], 0x24
; GFX9-NEXT:    s_load_dwordx4 s[4:7], s[0:1], 0x34
; GFX9-NEXT:    s_waitcnt lgkmcnt(0)
; GFX9-NEXT:    v_mov_b32_e32 v4, s2
; GFX9-NEXT:    v_mov_b32_e32 v0, s4
; GFX9-NEXT:    v_mov_b32_e32 v1, s5
; GFX9-NEXT:    v_mov_b32_e32 v2, s6
; GFX9-NEXT:    v_mov_b32_e32 v3, s7
; GFX9-NEXT:    ds_write2_b64 v4, v[0:1], v[2:3] offset1:1
; GFX9-NEXT:    s_endpgm
;
; GFX7-LABEL: store_lds_v4i32_align8:
; GFX7:       ; %bb.0:
; GFX7-NEXT:    s_load_dword s4, s[0:1], 0x9
; GFX7-NEXT:    s_load_dwordx4 s[0:3], s[0:1], 0xd
; GFX7-NEXT:    s_mov_b32 m0, -1
; GFX7-NEXT:    s_waitcnt lgkmcnt(0)
; GFX7-NEXT:    v_mov_b32_e32 v4, s4
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    v_mov_b32_e32 v1, s1
; GFX7-NEXT:    v_mov_b32_e32 v2, s2
; GFX7-NEXT:    v_mov_b32_e32 v3, s3
; GFX7-NEXT:    ds_write2_b64 v4, v[0:1], v[2:3] offset1:1
; GFX7-NEXT:    s_endpgm
  store <4 x i32> %x, <4 x i32> addrspace(3)* %out, align 8
  ret void
}

define amdgpu_kernel void @store_lds_v4i32_align16(<4 x i32> addrspace(3)* %out, <4 x i32> %x) {
; GFX9-LABEL: store_lds_v4i32_align16:
; GFX9:       ; %bb.0:
; GFX9-NEXT:    s_load_dword s2, s[0:1], 0x24
; GFX9-NEXT:    s_load_dwordx4 s[4:7], s[0:1], 0x34
; GFX9-NEXT:    s_waitcnt lgkmcnt(0)
; GFX9-NEXT:    v_mov_b32_e32 v4, s2
; GFX9-NEXT:    v_mov_b32_e32 v0, s4
; GFX9-NEXT:    v_mov_b32_e32 v1, s5
; GFX9-NEXT:    v_mov_b32_e32 v2, s6
; GFX9-NEXT:    v_mov_b32_e32 v3, s7
; GFX9-NEXT:    ds_write_b128 v4, v[0:3]
; GFX9-NEXT:    s_endpgm
;
; GFX7-LABEL: store_lds_v4i32_align16:
; GFX7:       ; %bb.0:
; GFX7-NEXT:    s_load_dword s4, s[0:1], 0x9
; GFX7-NEXT:    s_load_dwordx4 s[0:3], s[0:1], 0xd
; GFX7-NEXT:    s_mov_b32 m0, -1
; GFX7-NEXT:    s_waitcnt lgkmcnt(0)
; GFX7-NEXT:    v_mov_b32_e32 v4, s4
; GFX7-NEXT:    v_mov_b32_e32 v0, s0
; GFX7-NEXT:    v_mov_b32_e32 v1, s1
; GFX7-NEXT:    v_mov_b32_e32 v2, s2
; GFX7-NEXT:    v_mov_b32_e32 v3, s3
; GFX7-NEXT:    ds_write_b128 v4, v[0:3]
; GFX7-NEXT:    s_endpgm
  store <4 x i32> %x, <4 x i32> addrspace(3)* %out, align 16
  ret void
}
