; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=aarch64-linux-gnu -mattr=+sve < %s 2>%t | FileCheck %s
; RUN: FileCheck --check-prefix=WARN --allow-empty %s <%t

; If this check fails please read test/CodeGen/AArch64/README for instructions on how to resolve it.
; WARN-NOT: warning

define <vscale x 2 x i64>* @scalar_of_scalable_1(<vscale x 2 x i64>* %base) {
; CHECK-LABEL: scalar_of_scalable_1:
; CHECK:       // %bb.0:
; CHECK-NEXT:    rdvl x8, #4
; CHECK-NEXT:    add x0, x0, x8
; CHECK-NEXT:    ret
  %d = getelementptr <vscale x 2 x i64>, <vscale x 2 x i64>* %base, i64 4
  ret <vscale x 2 x i64>* %d
}

define <vscale x 2 x i64>* @scalar_of_scalable_2(<vscale x 2 x i64>* %base, i64 %offset) {
; CHECK-LABEL: scalar_of_scalable_2:
; CHECK:       // %bb.0:
; CHECK-NEXT:    rdvl x8, #1
; CHECK-NEXT:    madd x0, x1, x8, x0
; CHECK-NEXT:    ret
  %d = getelementptr <vscale x 2 x i64>, <vscale x 2 x i64>* %base, i64 %offset
  ret <vscale x 2 x i64>* %d
}

define <vscale x 2 x i32>* @scalar_of_scalable_3(<vscale x 2 x i32>* %base, i64 %offset) {
; CHECK-LABEL: scalar_of_scalable_3:
; CHECK:       // %bb.0:
; CHECK-NEXT:    cnth x8
; CHECK-NEXT:    madd x0, x1, x8, x0
; CHECK-NEXT:    ret
  %d = getelementptr <vscale x 2 x i32>, <vscale x 2 x i32>* %base, i64 %offset
  ret <vscale x 2 x i32>* %d
}

define <2 x <vscale x 2 x i64>*> @fixed_of_scalable_1(<vscale x 2 x i64>* %base) {
; CHECK-LABEL: fixed_of_scalable_1:
; CHECK:       // %bb.0:
; CHECK-NEXT:    rdvl x8, #1
; CHECK-NEXT:    dup v0.2d, x8
; CHECK-NEXT:    dup v1.2d, x0
; CHECK-NEXT:    add v0.2d, v1.2d, v0.2d
; CHECK-NEXT:    ret
  %d = getelementptr <vscale x 2 x i64>, <vscale x 2 x i64>* %base, <2 x i64> <i64 1, i64 1>
  ret <2 x <vscale x 2 x i64>*> %d
}

define <2 x <vscale x 2 x i64>*> @fixed_of_scalable_2(<2 x <vscale x 2 x i64>*> %base) {
; CHECK-LABEL: fixed_of_scalable_2:
; CHECK:       // %bb.0:
; CHECK-NEXT:    rdvl x8, #1
; CHECK-NEXT:    dup v1.2d, x8
; CHECK-NEXT:    add v0.2d, v0.2d, v1.2d
; CHECK-NEXT:    ret
  %d = getelementptr <vscale x 2 x i64>, <2 x <vscale x 2 x i64>*> %base, <2 x i64> <i64 1, i64 1>
  ret <2 x <vscale x 2 x i64>*> %d
}

define <vscale x 2 x i8*> @scalable_of_fixed_1(i8* %base) {
; CHECK-LABEL: scalable_of_fixed_1:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov z0.d, x0
; CHECK-NEXT:    add z0.d, z0.d, #1 // =0x1
; CHECK-NEXT:    ret
  %idx = shufflevector <vscale x 2 x i64> insertelement (<vscale x 2 x i64> undef, i64 1, i32 0), <vscale x 2 x i64> zeroinitializer, <vscale x 2 x i32> zeroinitializer
  %d = getelementptr i8, i8* %base, <vscale x 2 x i64> %idx
  ret <vscale x 2 x i8*> %d
}

define <vscale x 2 x i8*> @scalable_of_fixed_2(<vscale x 2 x i8*> %base) {
; CHECK-LABEL: scalable_of_fixed_2:
; CHECK:       // %bb.0:
; CHECK-NEXT:    add z0.d, z0.d, #1 // =0x1
; CHECK-NEXT:    ret
  %idx = shufflevector <vscale x 2 x i64> insertelement (<vscale x 2 x i64> undef, i64 1, i32 0), <vscale x 2 x i64> zeroinitializer, <vscale x 2 x i32> zeroinitializer
  %d = getelementptr i8, <vscale x 2 x i8*> %base, <vscale x 2 x i64> %idx
  ret <vscale x 2 x i8*> %d
}

define <vscale x 2 x i8*> @scalable_of_fixed_3(i8* %base, <vscale x 2 x i64> %idx) {
; CHECK-LABEL: scalable_of_fixed_3:
; CHECK:       // %bb.0:
; CHECK-NEXT:    mov z1.d, x0
; CHECK-NEXT:    add z0.d, z1.d, z0.d
; CHECK-NEXT:    ret
  %d = getelementptr i8, i8* %base, <vscale x 2 x i64> %idx
  ret <vscale x 2 x i8*> %d
}

define <vscale x 2 x i8*> @scalable_of_fixed_4(i8* %base, <vscale x 2 x i32> %idx) {
; CHECK-LABEL: scalable_of_fixed_4:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.d
; CHECK-NEXT:    sxtw z0.d, p0/m, z0.d
; CHECK-NEXT:    mov z1.d, x0
; CHECK-NEXT:    add z0.d, z1.d, z0.d
; CHECK-NEXT:    ret
  %d = getelementptr i8, i8* %base, <vscale x 2 x i32> %idx
  ret <vscale x 2 x i8*> %d
}

define <vscale x 2 x <vscale x 2 x i64>*> @scalable_of_scalable_1(<vscale x 2 x i64>* %base) {
; CHECK-LABEL: scalable_of_scalable_1:
; CHECK:       // %bb.0:
; CHECK-NEXT:    rdvl x8, #1
; CHECK-NEXT:    mov z1.d, x8
; CHECK-NEXT:    mov z0.d, x0
; CHECK-NEXT:    mul z1.d, z1.d, #1
; CHECK-NEXT:    add z0.d, z0.d, z1.d
; CHECK-NEXT:    ret
  %idx = shufflevector <vscale x 2 x i64> insertelement (<vscale x 2 x i64> undef, i64 1, i32 0), <vscale x 2 x i64> zeroinitializer, <vscale x 2 x i32> zeroinitializer
  %d = getelementptr <vscale x 2 x i64>, <vscale x 2 x i64>* %base, <vscale x 2 x i64> %idx
  ret <vscale x 2 x <vscale x 2 x i64>*> %d
}

define <vscale x 2 x <vscale x 2 x i64>*> @scalable_of_scalable_2(<vscale x 2 x <vscale x 2 x i64>*> %base) {
; CHECK-LABEL: scalable_of_scalable_2:
; CHECK:       // %bb.0:
; CHECK-NEXT:    rdvl x8, #1
; CHECK-NEXT:    mov z1.d, x8
; CHECK-NEXT:    mul z1.d, z1.d, #1
; CHECK-NEXT:    add z0.d, z0.d, z1.d
; CHECK-NEXT:    ret
  %idx = shufflevector <vscale x 2 x i64> insertelement (<vscale x 2 x i64> undef, i64 1, i32 0), <vscale x 2 x i64> zeroinitializer, <vscale x 2 x i32> zeroinitializer
  %d = getelementptr <vscale x 2 x i64>, <vscale x 2 x <vscale x 2 x i64>*> %base, <vscale x 2 x i64> %idx
  ret <vscale x 2 x <vscale x 2 x i64>*> %d
}

define <vscale x 2 x <vscale x 2 x i64>*> @scalable_of_scalable_3(<vscale x 2 x <vscale x 2 x i64>*> %base, <vscale x 2 x i32> %idx) {
; CHECK-LABEL: scalable_of_scalable_3:
; CHECK:       // %bb.0:
; CHECK-NEXT:    ptrue p0.d
; CHECK-NEXT:    rdvl x8, #1
; CHECK-NEXT:    sxtw z1.d, p0/m, z1.d
; CHECK-NEXT:    mov z2.d, x8
; CHECK-NEXT:    mul z1.d, p0/m, z1.d, z2.d
; CHECK-NEXT:    add z0.d, z0.d, z1.d
; CHECK-NEXT:    ret
  %d = getelementptr <vscale x 2 x i64>, <vscale x 2 x <vscale x 2 x i64>*> %base, <vscale x 2 x i32> %idx
  ret <vscale x 2 x <vscale x 2 x i64>*> %d
}
