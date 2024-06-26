; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+sse2 -disable-peephole | FileCheck %s --check-prefix=SSE
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+avx2 -disable-peephole | FileCheck %s --check-prefix=AVX
; RUN: llc < %s -mtriple=x86_64-unknown -mattr=+avx512vl,+avx512dq -disable-peephole | FileCheck %s --check-prefix=AVX512

;
; Float Comparisons
; Only equal/not-equal/ordered/unordered can be safely commuted
;

define <4 x i32> @commute_cmpps_eq(<4 x float>* %a0, <4 x float> %a1) {
; SSE-LABEL: commute_cmpps_eq:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpeqps (%rdi), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_eq:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeqps (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_eq:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeqps (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <4 x float>, <4 x float>* %a0
  %2 = fcmp oeq <4 x float> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i32>
  ret <4 x i32> %3
}

define <4 x i32> @commute_cmpps_ne(<4 x float>* %a0, <4 x float> %a1) {
; SSE-LABEL: commute_cmpps_ne:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpneqps (%rdi), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_ne:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneqps (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_ne:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneqps (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <4 x float>, <4 x float>* %a0
  %2 = fcmp une <4 x float> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i32>
  ret <4 x i32> %3
}

define <4 x i32> @commute_cmpps_ord(<4 x float>* %a0, <4 x float> %a1) {
; SSE-LABEL: commute_cmpps_ord:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpordps (%rdi), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_ord:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpordps (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_ord:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpordps (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <4 x float>, <4 x float>* %a0
  %2 = fcmp ord <4 x float> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i32>
  ret <4 x i32> %3
}

define <4 x i32> @commute_cmpps_uno(<4 x float>* %a0, <4 x float> %a1) {
; SSE-LABEL: commute_cmpps_uno:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpunordps (%rdi), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_uno:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpunordps (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_uno:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpunordps (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <4 x float>, <4 x float>* %a0
  %2 = fcmp uno <4 x float> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i32>
  ret <4 x i32> %3
}

define <4 x i32> @commute_cmpps_ueq(<4 x float>* %a0, <4 x float> %a1) {
; SSE-LABEL: commute_cmpps_ueq:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm1
; SSE-NEXT:    movaps %xmm1, %xmm2
; SSE-NEXT:    cmpeqps %xmm0, %xmm2
; SSE-NEXT:    cmpunordps %xmm1, %xmm0
; SSE-NEXT:    orps %xmm2, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_ueq:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeq_uqps (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_ueq:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeq_uqps (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <4 x float>, <4 x float>* %a0
  %2 = fcmp ueq <4 x float> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i32>
  ret <4 x i32> %3
}

define <4 x i32> @commute_cmpps_one(<4 x float>* %a0, <4 x float> %a1) {
; SSE-LABEL: commute_cmpps_one:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm1
; SSE-NEXT:    movaps %xmm1, %xmm2
; SSE-NEXT:    cmpneqps %xmm0, %xmm2
; SSE-NEXT:    cmpordps %xmm1, %xmm0
; SSE-NEXT:    andps %xmm2, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_one:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneq_oqps (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_one:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneq_oqps (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <4 x float>, <4 x float>* %a0
  %2 = fcmp one <4 x float> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i32>
  ret <4 x i32> %3
}

define <4 x i32> @commute_cmpps_lt(<4 x float>* %a0, <4 x float> %a1) {
; SSE-LABEL: commute_cmpps_lt:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm1
; SSE-NEXT:    cmpltps %xmm0, %xmm1
; SSE-NEXT:    movaps %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_lt:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps (%rdi), %xmm1
; AVX-NEXT:    vcmpltps %xmm0, %xmm1, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_lt:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vmovaps (%rdi), %xmm1
; AVX512-NEXT:    vcmpltps %xmm0, %xmm1, %xmm0
; AVX512-NEXT:    retq
  %1 = load <4 x float>, <4 x float>* %a0
  %2 = fcmp olt <4 x float> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i32>
  ret <4 x i32> %3
}

define <4 x i32> @commute_cmpps_le(<4 x float>* %a0, <4 x float> %a1) {
; SSE-LABEL: commute_cmpps_le:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm1
; SSE-NEXT:    cmpleps %xmm0, %xmm1
; SSE-NEXT:    movaps %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_le:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps (%rdi), %xmm1
; AVX-NEXT:    vcmpleps %xmm0, %xmm1, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_le:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vmovaps (%rdi), %xmm1
; AVX512-NEXT:    vcmpleps %xmm0, %xmm1, %xmm0
; AVX512-NEXT:    retq
  %1 = load <4 x float>, <4 x float>* %a0
  %2 = fcmp ole <4 x float> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i32>
  ret <4 x i32> %3
}

define <8 x i32> @commute_cmpps_eq_ymm(<8 x float>* %a0, <8 x float> %a1) {
; SSE-LABEL: commute_cmpps_eq_ymm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpeqps (%rdi), %xmm0
; SSE-NEXT:    cmpeqps 16(%rdi), %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_eq_ymm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeqps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_eq_ymm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeqps (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <8 x float>, <8 x float>* %a0
  %2 = fcmp oeq <8 x float> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i32>
  ret <8 x i32> %3
}

define <8 x i32> @commute_cmpps_ne_ymm(<8 x float>* %a0, <8 x float> %a1) {
; SSE-LABEL: commute_cmpps_ne_ymm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpneqps (%rdi), %xmm0
; SSE-NEXT:    cmpneqps 16(%rdi), %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_ne_ymm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneqps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_ne_ymm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneqps (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <8 x float>, <8 x float>* %a0
  %2 = fcmp une <8 x float> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i32>
  ret <8 x i32> %3
}

define <8 x i32> @commute_cmpps_ord_ymm(<8 x float>* %a0, <8 x float> %a1) {
; SSE-LABEL: commute_cmpps_ord_ymm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpordps (%rdi), %xmm0
; SSE-NEXT:    cmpordps 16(%rdi), %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_ord_ymm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpordps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_ord_ymm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpordps (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <8 x float>, <8 x float>* %a0
  %2 = fcmp ord <8 x float> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i32>
  ret <8 x i32> %3
}

define <8 x i32> @commute_cmpps_uno_ymm(<8 x float>* %a0, <8 x float> %a1) {
; SSE-LABEL: commute_cmpps_uno_ymm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpunordps (%rdi), %xmm0
; SSE-NEXT:    cmpunordps 16(%rdi), %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_uno_ymm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpunordps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_uno_ymm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpunordps (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <8 x float>, <8 x float>* %a0
  %2 = fcmp uno <8 x float> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i32>
  ret <8 x i32> %3
}

define <8 x i32> @commute_cmpps_ueq_ymm(<8 x float>* %a0, <8 x float> %a1) {
; SSE-LABEL: commute_cmpps_ueq_ymm:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm2
; SSE-NEXT:    movaps 16(%rdi), %xmm3
; SSE-NEXT:    movaps %xmm2, %xmm4
; SSE-NEXT:    cmpeqps %xmm0, %xmm4
; SSE-NEXT:    cmpunordps %xmm2, %xmm0
; SSE-NEXT:    orps %xmm4, %xmm0
; SSE-NEXT:    movaps %xmm3, %xmm2
; SSE-NEXT:    cmpeqps %xmm1, %xmm2
; SSE-NEXT:    cmpunordps %xmm3, %xmm1
; SSE-NEXT:    orps %xmm2, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_ueq_ymm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeq_uqps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_ueq_ymm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeq_uqps (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <8 x float>, <8 x float>* %a0
  %2 = fcmp ueq <8 x float> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i32>
  ret <8 x i32> %3
}

define <8 x i32> @commute_cmpps_one_ymm(<8 x float>* %a0, <8 x float> %a1) {
; SSE-LABEL: commute_cmpps_one_ymm:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm2
; SSE-NEXT:    movaps 16(%rdi), %xmm3
; SSE-NEXT:    movaps %xmm2, %xmm4
; SSE-NEXT:    cmpneqps %xmm0, %xmm4
; SSE-NEXT:    cmpordps %xmm2, %xmm0
; SSE-NEXT:    andps %xmm4, %xmm0
; SSE-NEXT:    movaps %xmm3, %xmm2
; SSE-NEXT:    cmpneqps %xmm1, %xmm2
; SSE-NEXT:    cmpordps %xmm3, %xmm1
; SSE-NEXT:    andps %xmm2, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_one_ymm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneq_oqps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_one_ymm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneq_oqps (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <8 x float>, <8 x float>* %a0
  %2 = fcmp one <8 x float> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i32>
  ret <8 x i32> %3
}

define <8 x i32> @commute_cmpps_lt_ymm(<8 x float>* %a0, <8 x float> %a1) {
; SSE-LABEL: commute_cmpps_lt_ymm:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm2
; SSE-NEXT:    movaps 16(%rdi), %xmm3
; SSE-NEXT:    cmpltps %xmm0, %xmm2
; SSE-NEXT:    cmpltps %xmm1, %xmm3
; SSE-NEXT:    movaps %xmm2, %xmm0
; SSE-NEXT:    movaps %xmm3, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_lt_ymm:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps (%rdi), %ymm1
; AVX-NEXT:    vcmpltps %ymm0, %ymm1, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_lt_ymm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vmovaps (%rdi), %ymm1
; AVX512-NEXT:    vcmpltps %ymm0, %ymm1, %ymm0
; AVX512-NEXT:    retq
  %1 = load <8 x float>, <8 x float>* %a0
  %2 = fcmp olt <8 x float> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i32>
  ret <8 x i32> %3
}

define <8 x i32> @commute_cmpps_le_ymm(<8 x float>* %a0, <8 x float> %a1) {
; SSE-LABEL: commute_cmpps_le_ymm:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm2
; SSE-NEXT:    movaps 16(%rdi), %xmm3
; SSE-NEXT:    cmpleps %xmm0, %xmm2
; SSE-NEXT:    cmpleps %xmm1, %xmm3
; SSE-NEXT:    movaps %xmm2, %xmm0
; SSE-NEXT:    movaps %xmm3, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_le_ymm:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps (%rdi), %ymm1
; AVX-NEXT:    vcmpleps %ymm0, %ymm1, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_le_ymm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vmovaps (%rdi), %ymm1
; AVX512-NEXT:    vcmpleps %ymm0, %ymm1, %ymm0
; AVX512-NEXT:    retq
  %1 = load <8 x float>, <8 x float>* %a0
  %2 = fcmp ole <8 x float> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i32>
  ret <8 x i32> %3
}

;
; Double Comparisons
; Only equal/not-equal/ordered/unordered can be safely commuted
;

define <2 x i64> @commute_cmppd_eq(<2 x double>* %a0, <2 x double> %a1) {
; SSE-LABEL: commute_cmppd_eq:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpeqpd (%rdi), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_eq:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeqpd (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_eq:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeqpd (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <2 x double>, <2 x double>* %a0
  %2 = fcmp oeq <2 x double> %1, %a1
  %3 = sext <2 x i1> %2 to <2 x i64>
  ret <2 x i64> %3
}

define <2 x i64> @commute_cmppd_ne(<2 x double>* %a0, <2 x double> %a1) {
; SSE-LABEL: commute_cmppd_ne:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpneqpd (%rdi), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_ne:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneqpd (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_ne:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneqpd (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <2 x double>, <2 x double>* %a0
  %2 = fcmp une <2 x double> %1, %a1
  %3 = sext <2 x i1> %2 to <2 x i64>
  ret <2 x i64> %3
}

define <2 x i64> @commute_cmppd_ord(<2 x double>* %a0, <2 x double> %a1) {
; SSE-LABEL: commute_cmppd_ord:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpordpd (%rdi), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_ord:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpordpd (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_ord:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpordpd (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <2 x double>, <2 x double>* %a0
  %2 = fcmp ord <2 x double> %1, %a1
  %3 = sext <2 x i1> %2 to <2 x i64>
  ret <2 x i64> %3
}

define <2 x i64> @commute_cmppd_ueq(<2 x double>* %a0, <2 x double> %a1) {
; SSE-LABEL: commute_cmppd_ueq:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm1
; SSE-NEXT:    movapd %xmm1, %xmm2
; SSE-NEXT:    cmpeqpd %xmm0, %xmm2
; SSE-NEXT:    cmpunordpd %xmm1, %xmm0
; SSE-NEXT:    orpd %xmm2, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_ueq:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeq_uqpd (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_ueq:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeq_uqpd (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <2 x double>, <2 x double>* %a0
  %2 = fcmp ueq <2 x double> %1, %a1
  %3 = sext <2 x i1> %2 to <2 x i64>
  ret <2 x i64> %3
}

define <2 x i64> @commute_cmppd_one(<2 x double>* %a0, <2 x double> %a1) {
; SSE-LABEL: commute_cmppd_one:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm1
; SSE-NEXT:    movapd %xmm1, %xmm2
; SSE-NEXT:    cmpneqpd %xmm0, %xmm2
; SSE-NEXT:    cmpordpd %xmm1, %xmm0
; SSE-NEXT:    andpd %xmm2, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_one:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneq_oqpd (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_one:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneq_oqpd (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <2 x double>, <2 x double>* %a0
  %2 = fcmp one <2 x double> %1, %a1
  %3 = sext <2 x i1> %2 to <2 x i64>
  ret <2 x i64> %3
}

define <2 x i64> @commute_cmppd_uno(<2 x double>* %a0, <2 x double> %a1) {
; SSE-LABEL: commute_cmppd_uno:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpunordpd (%rdi), %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_uno:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpunordpd (%rdi), %xmm0, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_uno:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpunordpd (%rdi), %xmm0, %xmm0
; AVX512-NEXT:    retq
  %1 = load <2 x double>, <2 x double>* %a0
  %2 = fcmp uno <2 x double> %1, %a1
  %3 = sext <2 x i1> %2 to <2 x i64>
  ret <2 x i64> %3
}

define <2 x i64> @commute_cmppd_lt(<2 x double>* %a0, <2 x double> %a1) {
; SSE-LABEL: commute_cmppd_lt:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm1
; SSE-NEXT:    cmpltpd %xmm0, %xmm1
; SSE-NEXT:    movapd %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_lt:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovapd (%rdi), %xmm1
; AVX-NEXT:    vcmpltpd %xmm0, %xmm1, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_lt:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vmovapd (%rdi), %xmm1
; AVX512-NEXT:    vcmpltpd %xmm0, %xmm1, %xmm0
; AVX512-NEXT:    retq
  %1 = load <2 x double>, <2 x double>* %a0
  %2 = fcmp olt <2 x double> %1, %a1
  %3 = sext <2 x i1> %2 to <2 x i64>
  ret <2 x i64> %3
}

define <2 x i64> @commute_cmppd_le(<2 x double>* %a0, <2 x double> %a1) {
; SSE-LABEL: commute_cmppd_le:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm1
; SSE-NEXT:    cmplepd %xmm0, %xmm1
; SSE-NEXT:    movapd %xmm1, %xmm0
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_le:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovapd (%rdi), %xmm1
; AVX-NEXT:    vcmplepd %xmm0, %xmm1, %xmm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_le:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vmovapd (%rdi), %xmm1
; AVX512-NEXT:    vcmplepd %xmm0, %xmm1, %xmm0
; AVX512-NEXT:    retq
  %1 = load <2 x double>, <2 x double>* %a0
  %2 = fcmp ole <2 x double> %1, %a1
  %3 = sext <2 x i1> %2 to <2 x i64>
  ret <2 x i64> %3
}

define <4 x i64> @commute_cmppd_eq_ymmm(<4 x double>* %a0, <4 x double> %a1) {
; SSE-LABEL: commute_cmppd_eq_ymmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpeqpd (%rdi), %xmm0
; SSE-NEXT:    cmpeqpd 16(%rdi), %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_eq_ymmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeqpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_eq_ymmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeqpd (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <4 x double>, <4 x double>* %a0
  %2 = fcmp oeq <4 x double> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i64>
  ret <4 x i64> %3
}

define <4 x i64> @commute_cmppd_ne_ymmm(<4 x double>* %a0, <4 x double> %a1) {
; SSE-LABEL: commute_cmppd_ne_ymmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpneqpd (%rdi), %xmm0
; SSE-NEXT:    cmpneqpd 16(%rdi), %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_ne_ymmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneqpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_ne_ymmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneqpd (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <4 x double>, <4 x double>* %a0
  %2 = fcmp une <4 x double> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i64>
  ret <4 x i64> %3
}

define <4 x i64> @commute_cmppd_ord_ymmm(<4 x double>* %a0, <4 x double> %a1) {
; SSE-LABEL: commute_cmppd_ord_ymmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpordpd (%rdi), %xmm0
; SSE-NEXT:    cmpordpd 16(%rdi), %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_ord_ymmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpordpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_ord_ymmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpordpd (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <4 x double>, <4 x double>* %a0
  %2 = fcmp ord <4 x double> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i64>
  ret <4 x i64> %3
}

define <4 x i64> @commute_cmppd_uno_ymmm(<4 x double>* %a0, <4 x double> %a1) {
; SSE-LABEL: commute_cmppd_uno_ymmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpunordpd (%rdi), %xmm0
; SSE-NEXT:    cmpunordpd 16(%rdi), %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_uno_ymmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpunordpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_uno_ymmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpunordpd (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <4 x double>, <4 x double>* %a0
  %2 = fcmp uno <4 x double> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i64>
  ret <4 x i64> %3
}

define <4 x i64> @commute_cmppd_ueq_ymmm(<4 x double>* %a0, <4 x double> %a1) {
; SSE-LABEL: commute_cmppd_ueq_ymmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm2
; SSE-NEXT:    movapd 16(%rdi), %xmm3
; SSE-NEXT:    movapd %xmm2, %xmm4
; SSE-NEXT:    cmpeqpd %xmm0, %xmm4
; SSE-NEXT:    cmpunordpd %xmm2, %xmm0
; SSE-NEXT:    orpd %xmm4, %xmm0
; SSE-NEXT:    movapd %xmm3, %xmm2
; SSE-NEXT:    cmpeqpd %xmm1, %xmm2
; SSE-NEXT:    cmpunordpd %xmm3, %xmm1
; SSE-NEXT:    orpd %xmm2, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_ueq_ymmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeq_uqpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_ueq_ymmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeq_uqpd (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <4 x double>, <4 x double>* %a0
  %2 = fcmp ueq <4 x double> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i64>
  ret <4 x i64> %3
}

define <4 x i64> @commute_cmppd_one_ymmm(<4 x double>* %a0, <4 x double> %a1) {
; SSE-LABEL: commute_cmppd_one_ymmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm2
; SSE-NEXT:    movapd 16(%rdi), %xmm3
; SSE-NEXT:    movapd %xmm2, %xmm4
; SSE-NEXT:    cmpneqpd %xmm0, %xmm4
; SSE-NEXT:    cmpordpd %xmm2, %xmm0
; SSE-NEXT:    andpd %xmm4, %xmm0
; SSE-NEXT:    movapd %xmm3, %xmm2
; SSE-NEXT:    cmpneqpd %xmm1, %xmm2
; SSE-NEXT:    cmpordpd %xmm3, %xmm1
; SSE-NEXT:    andpd %xmm2, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_one_ymmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneq_oqpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_one_ymmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneq_oqpd (%rdi), %ymm0, %ymm0
; AVX512-NEXT:    retq
  %1 = load <4 x double>, <4 x double>* %a0
  %2 = fcmp one <4 x double> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i64>
  ret <4 x i64> %3
}

define <4 x i64> @commute_cmppd_lt_ymmm(<4 x double>* %a0, <4 x double> %a1) {
; SSE-LABEL: commute_cmppd_lt_ymmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm2
; SSE-NEXT:    movapd 16(%rdi), %xmm3
; SSE-NEXT:    cmpltpd %xmm0, %xmm2
; SSE-NEXT:    cmpltpd %xmm1, %xmm3
; SSE-NEXT:    movapd %xmm2, %xmm0
; SSE-NEXT:    movapd %xmm3, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_lt_ymmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovapd (%rdi), %ymm1
; AVX-NEXT:    vcmpltpd %ymm0, %ymm1, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_lt_ymmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vmovapd (%rdi), %ymm1
; AVX512-NEXT:    vcmpltpd %ymm0, %ymm1, %ymm0
; AVX512-NEXT:    retq
  %1 = load <4 x double>, <4 x double>* %a0
  %2 = fcmp olt <4 x double> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i64>
  ret <4 x i64> %3
}

define <4 x i64> @commute_cmppd_le_ymmm(<4 x double>* %a0, <4 x double> %a1) {
; SSE-LABEL: commute_cmppd_le_ymmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm2
; SSE-NEXT:    movapd 16(%rdi), %xmm3
; SSE-NEXT:    cmplepd %xmm0, %xmm2
; SSE-NEXT:    cmplepd %xmm1, %xmm3
; SSE-NEXT:    movapd %xmm2, %xmm0
; SSE-NEXT:    movapd %xmm3, %xmm1
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_le_ymmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovapd (%rdi), %ymm1
; AVX-NEXT:    vcmplepd %ymm0, %ymm1, %ymm0
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_le_ymmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vmovapd (%rdi), %ymm1
; AVX512-NEXT:    vcmplepd %ymm0, %ymm1, %ymm0
; AVX512-NEXT:    retq
  %1 = load <4 x double>, <4 x double>* %a0
  %2 = fcmp ole <4 x double> %1, %a1
  %3 = sext <4 x i1> %2 to <4 x i64>
  ret <4 x i64> %3
}

define <16 x i32> @commute_cmpps_eq_zmm(<16 x float>* %a0, <16 x float> %a1) {
; SSE-LABEL: commute_cmpps_eq_zmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpeqps (%rdi), %xmm0
; SSE-NEXT:    cmpeqps 16(%rdi), %xmm1
; SSE-NEXT:    cmpeqps 32(%rdi), %xmm2
; SSE-NEXT:    cmpeqps 48(%rdi), %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_eq_zmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeqps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpeqps 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_eq_zmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeqps (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2d %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <16 x float>, <16 x float>* %a0
  %2 = fcmp oeq <16 x float> %1, %a1
  %3 = sext <16 x i1> %2 to <16 x i32>
  ret <16 x i32> %3
}

define <16 x i32> @commute_cmpps_ne_zmm(<16 x float>* %a0, <16 x float> %a1) {
; SSE-LABEL: commute_cmpps_ne_zmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpneqps (%rdi), %xmm0
; SSE-NEXT:    cmpneqps 16(%rdi), %xmm1
; SSE-NEXT:    cmpneqps 32(%rdi), %xmm2
; SSE-NEXT:    cmpneqps 48(%rdi), %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_ne_zmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneqps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpneqps 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_ne_zmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneqps (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2d %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <16 x float>, <16 x float>* %a0
  %2 = fcmp une <16 x float> %1, %a1
  %3 = sext <16 x i1> %2 to <16 x i32>
  ret <16 x i32> %3
}

define <16 x i32> @commute_cmpps_ord_zmm(<16 x float>* %a0, <16 x float> %a1) {
; SSE-LABEL: commute_cmpps_ord_zmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpordps (%rdi), %xmm0
; SSE-NEXT:    cmpordps 16(%rdi), %xmm1
; SSE-NEXT:    cmpordps 32(%rdi), %xmm2
; SSE-NEXT:    cmpordps 48(%rdi), %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_ord_zmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpordps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpordps 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_ord_zmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpordps (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2d %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <16 x float>, <16 x float>* %a0
  %2 = fcmp ord <16 x float> %1, %a1
  %3 = sext <16 x i1> %2 to <16 x i32>
  ret <16 x i32> %3
}

define <16 x i32> @commute_cmpps_uno_zmm(<16 x float>* %a0, <16 x float> %a1) {
; SSE-LABEL: commute_cmpps_uno_zmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpunordps (%rdi), %xmm0
; SSE-NEXT:    cmpunordps 16(%rdi), %xmm1
; SSE-NEXT:    cmpunordps 32(%rdi), %xmm2
; SSE-NEXT:    cmpunordps 48(%rdi), %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_uno_zmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpunordps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpunordps 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_uno_zmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpunordps (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2d %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <16 x float>, <16 x float>* %a0
  %2 = fcmp uno <16 x float> %1, %a1
  %3 = sext <16 x i1> %2 to <16 x i32>
  ret <16 x i32> %3
}

define <16 x i32> @commute_cmpps_ueq_zmm(<16 x float>* %a0, <16 x float> %a1) {
; SSE-LABEL: commute_cmpps_ueq_zmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm4
; SSE-NEXT:    movaps 16(%rdi), %xmm5
; SSE-NEXT:    movaps 32(%rdi), %xmm6
; SSE-NEXT:    movaps 48(%rdi), %xmm7
; SSE-NEXT:    movaps %xmm4, %xmm8
; SSE-NEXT:    cmpeqps %xmm0, %xmm8
; SSE-NEXT:    cmpunordps %xmm4, %xmm0
; SSE-NEXT:    orps %xmm8, %xmm0
; SSE-NEXT:    movaps %xmm5, %xmm4
; SSE-NEXT:    cmpeqps %xmm1, %xmm4
; SSE-NEXT:    cmpunordps %xmm5, %xmm1
; SSE-NEXT:    orps %xmm4, %xmm1
; SSE-NEXT:    movaps %xmm6, %xmm4
; SSE-NEXT:    cmpeqps %xmm2, %xmm4
; SSE-NEXT:    cmpunordps %xmm6, %xmm2
; SSE-NEXT:    orps %xmm4, %xmm2
; SSE-NEXT:    movaps %xmm7, %xmm4
; SSE-NEXT:    cmpeqps %xmm3, %xmm4
; SSE-NEXT:    cmpunordps %xmm7, %xmm3
; SSE-NEXT:    orps %xmm4, %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_ueq_zmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeq_uqps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpeq_uqps 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_ueq_zmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeq_uqps (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2d %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <16 x float>, <16 x float>* %a0
  %2 = fcmp ueq <16 x float> %1, %a1
  %3 = sext <16 x i1> %2 to <16 x i32>
  ret <16 x i32> %3
}

define <16 x i32> @commute_cmpps_one_zmm(<16 x float>* %a0, <16 x float> %a1) {
; SSE-LABEL: commute_cmpps_one_zmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm4
; SSE-NEXT:    movaps 16(%rdi), %xmm5
; SSE-NEXT:    movaps 32(%rdi), %xmm6
; SSE-NEXT:    movaps 48(%rdi), %xmm7
; SSE-NEXT:    movaps %xmm4, %xmm8
; SSE-NEXT:    cmpneqps %xmm0, %xmm8
; SSE-NEXT:    cmpordps %xmm4, %xmm0
; SSE-NEXT:    andps %xmm8, %xmm0
; SSE-NEXT:    movaps %xmm5, %xmm4
; SSE-NEXT:    cmpneqps %xmm1, %xmm4
; SSE-NEXT:    cmpordps %xmm5, %xmm1
; SSE-NEXT:    andps %xmm4, %xmm1
; SSE-NEXT:    movaps %xmm6, %xmm4
; SSE-NEXT:    cmpneqps %xmm2, %xmm4
; SSE-NEXT:    cmpordps %xmm6, %xmm2
; SSE-NEXT:    andps %xmm4, %xmm2
; SSE-NEXT:    movaps %xmm7, %xmm4
; SSE-NEXT:    cmpneqps %xmm3, %xmm4
; SSE-NEXT:    cmpordps %xmm7, %xmm3
; SSE-NEXT:    andps %xmm4, %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_one_zmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneq_oqps (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpneq_oqps 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_one_zmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneq_oqps (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2d %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <16 x float>, <16 x float>* %a0
  %2 = fcmp one <16 x float> %1, %a1
  %3 = sext <16 x i1> %2 to <16 x i32>
  ret <16 x i32> %3
}

define <16 x i32> @commute_cmpps_lt_zmm(<16 x float>* %a0, <16 x float> %a1) {
; SSE-LABEL: commute_cmpps_lt_zmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm4
; SSE-NEXT:    movaps 16(%rdi), %xmm5
; SSE-NEXT:    movaps 32(%rdi), %xmm6
; SSE-NEXT:    movaps 48(%rdi), %xmm7
; SSE-NEXT:    cmpltps %xmm0, %xmm4
; SSE-NEXT:    cmpltps %xmm1, %xmm5
; SSE-NEXT:    cmpltps %xmm2, %xmm6
; SSE-NEXT:    cmpltps %xmm3, %xmm7
; SSE-NEXT:    movaps %xmm4, %xmm0
; SSE-NEXT:    movaps %xmm5, %xmm1
; SSE-NEXT:    movaps %xmm6, %xmm2
; SSE-NEXT:    movaps %xmm7, %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_lt_zmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps (%rdi), %ymm2
; AVX-NEXT:    vmovaps 32(%rdi), %ymm3
; AVX-NEXT:    vcmpltps %ymm0, %ymm2, %ymm0
; AVX-NEXT:    vcmpltps %ymm1, %ymm3, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_lt_zmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpgtps (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2d %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <16 x float>, <16 x float>* %a0
  %2 = fcmp olt <16 x float> %1, %a1
  %3 = sext <16 x i1> %2 to <16 x i32>
  ret <16 x i32> %3
}

define <16 x i32> @commute_cmpps_le_zmm(<16 x float>* %a0, <16 x float> %a1) {
; SSE-LABEL: commute_cmpps_le_zmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movaps (%rdi), %xmm4
; SSE-NEXT:    movaps 16(%rdi), %xmm5
; SSE-NEXT:    movaps 32(%rdi), %xmm6
; SSE-NEXT:    movaps 48(%rdi), %xmm7
; SSE-NEXT:    cmpleps %xmm0, %xmm4
; SSE-NEXT:    cmpleps %xmm1, %xmm5
; SSE-NEXT:    cmpleps %xmm2, %xmm6
; SSE-NEXT:    cmpleps %xmm3, %xmm7
; SSE-NEXT:    movaps %xmm4, %xmm0
; SSE-NEXT:    movaps %xmm5, %xmm1
; SSE-NEXT:    movaps %xmm6, %xmm2
; SSE-NEXT:    movaps %xmm7, %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmpps_le_zmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovaps (%rdi), %ymm2
; AVX-NEXT:    vmovaps 32(%rdi), %ymm3
; AVX-NEXT:    vcmpleps %ymm0, %ymm2, %ymm0
; AVX-NEXT:    vcmpleps %ymm1, %ymm3, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmpps_le_zmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpgeps (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2d %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <16 x float>, <16 x float>* %a0
  %2 = fcmp ole <16 x float> %1, %a1
  %3 = sext <16 x i1> %2 to <16 x i32>
  ret <16 x i32> %3
}

define <8 x i64> @commute_cmppd_eq_zmmm(<8 x double>* %a0, <8 x double> %a1) {
; SSE-LABEL: commute_cmppd_eq_zmmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpeqpd (%rdi), %xmm0
; SSE-NEXT:    cmpeqpd 16(%rdi), %xmm1
; SSE-NEXT:    cmpeqpd 32(%rdi), %xmm2
; SSE-NEXT:    cmpeqpd 48(%rdi), %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_eq_zmmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeqpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpeqpd 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_eq_zmmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeqpd (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2q %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <8 x double>, <8 x double>* %a0
  %2 = fcmp oeq <8 x double> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i64>
  ret <8 x i64> %3
}

define <8 x i64> @commute_cmppd_ne_zmmm(<8 x double>* %a0, <8 x double> %a1) {
; SSE-LABEL: commute_cmppd_ne_zmmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpneqpd (%rdi), %xmm0
; SSE-NEXT:    cmpneqpd 16(%rdi), %xmm1
; SSE-NEXT:    cmpneqpd 32(%rdi), %xmm2
; SSE-NEXT:    cmpneqpd 48(%rdi), %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_ne_zmmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneqpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpneqpd 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_ne_zmmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneqpd (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2q %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <8 x double>, <8 x double>* %a0
  %2 = fcmp une <8 x double> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i64>
  ret <8 x i64> %3
}

define <8 x i64> @commute_cmppd_ord_zmmm(<8 x double>* %a0, <8 x double> %a1) {
; SSE-LABEL: commute_cmppd_ord_zmmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpordpd (%rdi), %xmm0
; SSE-NEXT:    cmpordpd 16(%rdi), %xmm1
; SSE-NEXT:    cmpordpd 32(%rdi), %xmm2
; SSE-NEXT:    cmpordpd 48(%rdi), %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_ord_zmmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpordpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpordpd 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_ord_zmmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpordpd (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2q %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <8 x double>, <8 x double>* %a0
  %2 = fcmp ord <8 x double> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i64>
  ret <8 x i64> %3
}

define <8 x i64> @commute_cmppd_uno_zmmm(<8 x double>* %a0, <8 x double> %a1) {
; SSE-LABEL: commute_cmppd_uno_zmmm:
; SSE:       # %bb.0:
; SSE-NEXT:    cmpunordpd (%rdi), %xmm0
; SSE-NEXT:    cmpunordpd 16(%rdi), %xmm1
; SSE-NEXT:    cmpunordpd 32(%rdi), %xmm2
; SSE-NEXT:    cmpunordpd 48(%rdi), %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_uno_zmmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpunordpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpunordpd 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_uno_zmmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpunordpd (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2q %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <8 x double>, <8 x double>* %a0
  %2 = fcmp uno <8 x double> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i64>
  ret <8 x i64> %3
}

define <8 x i64> @commute_cmppd_ueq_zmmm(<8 x double>* %a0, <8 x double> %a1) {
; SSE-LABEL: commute_cmppd_ueq_zmmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm4
; SSE-NEXT:    movapd 16(%rdi), %xmm5
; SSE-NEXT:    movapd 32(%rdi), %xmm6
; SSE-NEXT:    movapd 48(%rdi), %xmm7
; SSE-NEXT:    movapd %xmm4, %xmm8
; SSE-NEXT:    cmpeqpd %xmm0, %xmm8
; SSE-NEXT:    cmpunordpd %xmm4, %xmm0
; SSE-NEXT:    orpd %xmm8, %xmm0
; SSE-NEXT:    movapd %xmm5, %xmm4
; SSE-NEXT:    cmpeqpd %xmm1, %xmm4
; SSE-NEXT:    cmpunordpd %xmm5, %xmm1
; SSE-NEXT:    orpd %xmm4, %xmm1
; SSE-NEXT:    movapd %xmm6, %xmm4
; SSE-NEXT:    cmpeqpd %xmm2, %xmm4
; SSE-NEXT:    cmpunordpd %xmm6, %xmm2
; SSE-NEXT:    orpd %xmm4, %xmm2
; SSE-NEXT:    movapd %xmm7, %xmm4
; SSE-NEXT:    cmpeqpd %xmm3, %xmm4
; SSE-NEXT:    cmpunordpd %xmm7, %xmm3
; SSE-NEXT:    orpd %xmm4, %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_ueq_zmmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpeq_uqpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpeq_uqpd 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_ueq_zmmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpeq_uqpd (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2q %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <8 x double>, <8 x double>* %a0
  %2 = fcmp ueq <8 x double> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i64>
  ret <8 x i64> %3
}

define <8 x i64> @commute_cmppd_one_zmmm(<8 x double>* %a0, <8 x double> %a1) {
; SSE-LABEL: commute_cmppd_one_zmmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm4
; SSE-NEXT:    movapd 16(%rdi), %xmm5
; SSE-NEXT:    movapd 32(%rdi), %xmm6
; SSE-NEXT:    movapd 48(%rdi), %xmm7
; SSE-NEXT:    movapd %xmm4, %xmm8
; SSE-NEXT:    cmpneqpd %xmm0, %xmm8
; SSE-NEXT:    cmpordpd %xmm4, %xmm0
; SSE-NEXT:    andpd %xmm8, %xmm0
; SSE-NEXT:    movapd %xmm5, %xmm4
; SSE-NEXT:    cmpneqpd %xmm1, %xmm4
; SSE-NEXT:    cmpordpd %xmm5, %xmm1
; SSE-NEXT:    andpd %xmm4, %xmm1
; SSE-NEXT:    movapd %xmm6, %xmm4
; SSE-NEXT:    cmpneqpd %xmm2, %xmm4
; SSE-NEXT:    cmpordpd %xmm6, %xmm2
; SSE-NEXT:    andpd %xmm4, %xmm2
; SSE-NEXT:    movapd %xmm7, %xmm4
; SSE-NEXT:    cmpneqpd %xmm3, %xmm4
; SSE-NEXT:    cmpordpd %xmm7, %xmm3
; SSE-NEXT:    andpd %xmm4, %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_one_zmmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vcmpneq_oqpd (%rdi), %ymm0, %ymm0
; AVX-NEXT:    vcmpneq_oqpd 32(%rdi), %ymm1, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_one_zmmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpneq_oqpd (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2q %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <8 x double>, <8 x double>* %a0
  %2 = fcmp one <8 x double> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i64>
  ret <8 x i64> %3
}

define <8 x i64> @commute_cmppd_lt_zmmm(<8 x double>* %a0, <8 x double> %a1) {
; SSE-LABEL: commute_cmppd_lt_zmmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm4
; SSE-NEXT:    movapd 16(%rdi), %xmm5
; SSE-NEXT:    movapd 32(%rdi), %xmm6
; SSE-NEXT:    movapd 48(%rdi), %xmm7
; SSE-NEXT:    cmpltpd %xmm0, %xmm4
; SSE-NEXT:    cmpltpd %xmm1, %xmm5
; SSE-NEXT:    cmpltpd %xmm2, %xmm6
; SSE-NEXT:    cmpltpd %xmm3, %xmm7
; SSE-NEXT:    movapd %xmm4, %xmm0
; SSE-NEXT:    movapd %xmm5, %xmm1
; SSE-NEXT:    movapd %xmm6, %xmm2
; SSE-NEXT:    movapd %xmm7, %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_lt_zmmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovapd (%rdi), %ymm2
; AVX-NEXT:    vmovapd 32(%rdi), %ymm3
; AVX-NEXT:    vcmpltpd %ymm0, %ymm2, %ymm0
; AVX-NEXT:    vcmpltpd %ymm1, %ymm3, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_lt_zmmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpgtpd (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2q %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <8 x double>, <8 x double>* %a0
  %2 = fcmp olt <8 x double> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i64>
  ret <8 x i64> %3
}

define <8 x i64> @commute_cmppd_le_zmmm(<8 x double>* %a0, <8 x double> %a1) {
; SSE-LABEL: commute_cmppd_le_zmmm:
; SSE:       # %bb.0:
; SSE-NEXT:    movapd (%rdi), %xmm4
; SSE-NEXT:    movapd 16(%rdi), %xmm5
; SSE-NEXT:    movapd 32(%rdi), %xmm6
; SSE-NEXT:    movapd 48(%rdi), %xmm7
; SSE-NEXT:    cmplepd %xmm0, %xmm4
; SSE-NEXT:    cmplepd %xmm1, %xmm5
; SSE-NEXT:    cmplepd %xmm2, %xmm6
; SSE-NEXT:    cmplepd %xmm3, %xmm7
; SSE-NEXT:    movapd %xmm4, %xmm0
; SSE-NEXT:    movapd %xmm5, %xmm1
; SSE-NEXT:    movapd %xmm6, %xmm2
; SSE-NEXT:    movapd %xmm7, %xmm3
; SSE-NEXT:    retq
;
; AVX-LABEL: commute_cmppd_le_zmmm:
; AVX:       # %bb.0:
; AVX-NEXT:    vmovapd (%rdi), %ymm2
; AVX-NEXT:    vmovapd 32(%rdi), %ymm3
; AVX-NEXT:    vcmplepd %ymm0, %ymm2, %ymm0
; AVX-NEXT:    vcmplepd %ymm1, %ymm3, %ymm1
; AVX-NEXT:    retq
;
; AVX512-LABEL: commute_cmppd_le_zmmm:
; AVX512:       # %bb.0:
; AVX512-NEXT:    vcmpgepd (%rdi), %zmm0, %k0
; AVX512-NEXT:    vpmovm2q %k0, %zmm0
; AVX512-NEXT:    retq
  %1 = load <8 x double>, <8 x double>* %a0
  %2 = fcmp ole <8 x double> %1, %a1
  %3 = sext <8 x i1> %2 to <8 x i64>
  ret <8 x i64> %3
}
