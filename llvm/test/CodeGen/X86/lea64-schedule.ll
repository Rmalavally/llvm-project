; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=x86-64      | FileCheck %s --check-prefix=CHECK --check-prefix=GENERIC
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=atom        | FileCheck %s --check-prefix=CHECK --check-prefix=ATOM
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=slm         | FileCheck %s --check-prefix=CHECK --check-prefix=SLM
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=sandybridge | FileCheck %s --check-prefix=CHECK --check-prefix=SANDY
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=ivybridge   | FileCheck %s --check-prefix=CHECK --check-prefix=SANDY
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=haswell     | FileCheck %s --check-prefix=CHECK --check-prefix=HASWELL
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=skylake     | FileCheck %s --check-prefix=CHECK --check-prefix=HASWELL
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=knl         | FileCheck %s --check-prefix=CHECK --check-prefix=HASWELL
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=btver2      | FileCheck %s --check-prefix=CHECK --check-prefix=BTVER2
; RUN: llc < %s -mtriple=x86_64-unknown-unknown -print-schedule -mcpu=znver1      | FileCheck %s --check-prefix=CHECK --check-prefix=BTVER2

define i64 @test_lea_offset(i64) {
; GENERIC-LABEL: test_lea_offset:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq -24(%rdi), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_offset:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq -24(%rdi), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_offset:
; SLM:       # BB#0:
; SLM-NEXT:    leaq -24(%rdi), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_offset:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq -24(%rdi), %rax # sched: [1:0.50]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_offset:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq -24(%rdi), %rax # sched: [1:0.50]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_offset:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq -24(%rdi), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %2 = add nsw i64 %0, -24
  ret i64 %2
}

define i64 @test_lea_offset_big(i64) {
; GENERIC-LABEL: test_lea_offset_big:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq 1024(%rdi), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_offset_big:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq 1024(%rdi), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_offset_big:
; SLM:       # BB#0:
; SLM-NEXT:    leaq 1024(%rdi), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_offset_big:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq 1024(%rdi), %rax # sched: [1:0.50]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_offset_big:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq 1024(%rdi), %rax # sched: [1:0.50]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_offset_big:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq 1024(%rdi), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %2 = add nsw i64 %0, 1024
  ret i64 %2
}

; Function Attrs: norecurse nounwind readnone uwtable
define i64 @test_lea_add(i64, i64) {
; GENERIC-LABEL: test_lea_add:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq (%rdi,%rsi), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_add:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq (%rdi,%rsi), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_add:
; SLM:       # BB#0:
; SLM-NEXT:    leaq (%rdi,%rsi), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_add:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq (%rdi,%rsi), %rax # sched: [1:0.50]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_add:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq (%rdi,%rsi), %rax # sched: [1:0.50]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_add:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq (%rdi,%rsi), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %3 = add nsw i64 %1, %0
  ret i64 %3
}

define i64 @test_lea_add_offset(i64, i64) {
; GENERIC-LABEL: test_lea_add_offset:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq 16(%rdi,%rsi), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_add_offset:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq 16(%rdi,%rsi), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_add_offset:
; SLM:       # BB#0:
; SLM-NEXT:    leaq 16(%rdi,%rsi), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_add_offset:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq (%rdi,%rsi), %rax # sched: [1:0.50]
; SANDY-NEXT:    addq $16, %rax # sched: [1:0.33]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_add_offset:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq (%rdi,%rsi), %rax # sched: [1:0.50]
; HASWELL-NEXT:    addq $16, %rax # sched: [1:0.25]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_add_offset:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq 16(%rdi,%rsi), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %3 = add i64 %0, 16
  %4 = add i64 %3, %1
  ret i64 %4
}

define i64 @test_lea_add_offset_big(i64, i64) {
; GENERIC-LABEL: test_lea_add_offset_big:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq -4096(%rdi,%rsi), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_add_offset_big:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq -4096(%rdi,%rsi), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_add_offset_big:
; SLM:       # BB#0:
; SLM-NEXT:    leaq -4096(%rdi,%rsi), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_add_offset_big:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq (%rdi,%rsi), %rax # sched: [1:0.50]
; SANDY-NEXT:    addq $-4096, %rax # imm = 0xF000
; SANDY-NEXT:    # sched: [1:0.33]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_add_offset_big:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq (%rdi,%rsi), %rax # sched: [1:0.50]
; HASWELL-NEXT:    addq $-4096, %rax # imm = 0xF000
; HASWELL-NEXT:    # sched: [1:0.25]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_add_offset_big:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq -4096(%rdi,%rsi), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %3 = add i64 %0, -4096
  %4 = add i64 %3, %1
  ret i64 %4
}

define i64 @test_lea_mul(i64) {
; GENERIC-LABEL: test_lea_mul:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq (%rdi,%rdi,2), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_mul:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq (%rdi,%rdi,2), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_mul:
; SLM:       # BB#0:
; SLM-NEXT:    leaq (%rdi,%rdi,2), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_mul:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq (%rdi,%rdi,2), %rax # sched: [1:0.50]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_mul:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq (%rdi,%rdi,2), %rax # sched: [1:0.50]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_mul:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq (%rdi,%rdi,2), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %2 = mul nsw i64 %0, 3
  ret i64 %2
}

define i64 @test_lea_mul_offset(i64) {
; GENERIC-LABEL: test_lea_mul_offset:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq -32(%rdi,%rdi,2), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_mul_offset:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq -32(%rdi,%rdi,2), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_mul_offset:
; SLM:       # BB#0:
; SLM-NEXT:    leaq -32(%rdi,%rdi,2), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_mul_offset:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq (%rdi,%rdi,2), %rax # sched: [1:0.50]
; SANDY-NEXT:    addq $-32, %rax # sched: [1:0.33]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_mul_offset:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq (%rdi,%rdi,2), %rax # sched: [1:0.50]
; HASWELL-NEXT:    addq $-32, %rax # sched: [1:0.25]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_mul_offset:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq -32(%rdi,%rdi,2), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %2 = mul nsw i64 %0, 3
  %3 = add nsw i64 %2, -32
  ret i64 %3
}

define i64 @test_lea_mul_offset_big(i64) {
; GENERIC-LABEL: test_lea_mul_offset_big:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq 10000(%rdi,%rdi,8), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_mul_offset_big:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq 10000(%rdi,%rdi,8), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_mul_offset_big:
; SLM:       # BB#0:
; SLM-NEXT:    leaq 10000(%rdi,%rdi,8), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_mul_offset_big:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq (%rdi,%rdi,8), %rax # sched: [1:0.50]
; SANDY-NEXT:    addq $10000, %rax # imm = 0x2710
; SANDY-NEXT:    # sched: [1:0.33]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_mul_offset_big:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq (%rdi,%rdi,8), %rax # sched: [1:0.50]
; HASWELL-NEXT:    addq $10000, %rax # imm = 0x2710
; HASWELL-NEXT:    # sched: [1:0.25]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_mul_offset_big:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq 10000(%rdi,%rdi,8), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %2 = mul nsw i64 %0, 9
  %3 = add nsw i64 %2, 10000
  ret i64 %3
}

define i64 @test_lea_add_scale(i64, i64) {
; GENERIC-LABEL: test_lea_add_scale:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq (%rdi,%rsi,2), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_add_scale:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq (%rdi,%rsi,2), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_add_scale:
; SLM:       # BB#0:
; SLM-NEXT:    leaq (%rdi,%rsi,2), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_add_scale:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq (%rdi,%rsi,2), %rax # sched: [1:0.50]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_add_scale:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq (%rdi,%rsi,2), %rax # sched: [1:0.50]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_add_scale:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq (%rdi,%rsi,2), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %3 = shl i64 %1, 1
  %4 = add nsw i64 %3, %0
  ret i64 %4
}

define i64 @test_lea_add_scale_offset(i64, i64) {
; GENERIC-LABEL: test_lea_add_scale_offset:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq 96(%rdi,%rsi,4), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_add_scale_offset:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq 96(%rdi,%rsi,4), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_add_scale_offset:
; SLM:       # BB#0:
; SLM-NEXT:    leaq 96(%rdi,%rsi,4), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_add_scale_offset:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq (%rdi,%rsi,4), %rax # sched: [1:0.50]
; SANDY-NEXT:    addq $96, %rax # sched: [1:0.33]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_add_scale_offset:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq (%rdi,%rsi,4), %rax # sched: [1:0.50]
; HASWELL-NEXT:    addq $96, %rax # sched: [1:0.25]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_add_scale_offset:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq 96(%rdi,%rsi,4), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %3 = shl i64 %1, 2
  %4 = add i64 %0, 96
  %5 = add i64 %4, %3
  ret i64 %5
}

define i64 @test_lea_add_scale_offset_big(i64, i64) {
; GENERIC-LABEL: test_lea_add_scale_offset_big:
; GENERIC:       # BB#0:
; GENERIC-NEXT:    leaq -1200(%rdi,%rsi,8), %rax # sched: [1:0.50]
; GENERIC-NEXT:    retq # sched: [1:1.00]
;
; ATOM-LABEL: test_lea_add_scale_offset_big:
; ATOM:       # BB#0:
; ATOM-NEXT:    leaq -1200(%rdi,%rsi,8), %rax
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    nop
; ATOM-NEXT:    retq
;
; SLM-LABEL: test_lea_add_scale_offset_big:
; SLM:       # BB#0:
; SLM-NEXT:    leaq -1200(%rdi,%rsi,8), %rax # sched: [1:1.00]
; SLM-NEXT:    retq # sched: [4:1.00]
;
; SANDY-LABEL: test_lea_add_scale_offset_big:
; SANDY:       # BB#0:
; SANDY-NEXT:    leaq (%rdi,%rsi,8), %rax # sched: [1:0.50]
; SANDY-NEXT:    addq $-1200, %rax # imm = 0xFB50
; SANDY-NEXT:    # sched: [1:0.33]
; SANDY-NEXT:    retq # sched: [1:1.00]
;
; HASWELL-LABEL: test_lea_add_scale_offset_big:
; HASWELL:       # BB#0:
; HASWELL-NEXT:    leaq (%rdi,%rsi,8), %rax # sched: [1:0.50]
; HASWELL-NEXT:    addq $-1200, %rax # imm = 0xFB50
; HASWELL-NEXT:    # sched: [1:0.25]
; HASWELL-NEXT:    retq # sched: [1:1.00]
;
; BTVER2-LABEL: test_lea_add_scale_offset_big:
; BTVER2:       # BB#0:
; BTVER2-NEXT:    leaq -1200(%rdi,%rsi,8), %rax # sched: [1:0.50]
; BTVER2-NEXT:    retq # sched: [4:1.00]
  %3 = shl i64 %1, 3
  %4 = add i64 %0, -1200
  %5 = add i64 %4, %3
  ret i64 %5
}
