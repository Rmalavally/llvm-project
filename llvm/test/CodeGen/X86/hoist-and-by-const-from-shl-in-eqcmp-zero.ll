; NOTE: Assertions have been autogenerated by utils/update_llc_test_checks.py
; RUN: llc -mtriple=i686-unknown-linux-gnu -mattr=+sse,sse2            < %s | FileCheck %s --check-prefixes=CHECK,X86,X86-NOBMI
; RUN: llc -mtriple=i686-unknown-linux-gnu -mattr=+sse,sse2,+bmi       < %s | FileCheck %s --check-prefixes=CHECK,X86,X86-BMI,X86-BMI1
; RUN: llc -mtriple=i686-unknown-linux-gnu -mattr=+sse,sse2,+bmi,+bmi2 < %s | FileCheck %s --check-prefixes=CHECK,X86,X86-BMI,X86-BMI12
; RUN: llc -mtriple=x86_64-unknown-linux-gnu -mattr=+sse,sse2            < %s | FileCheck %s --check-prefixes=CHECK,X64,X64-NOBMI
; RUN: llc -mtriple=x86_64-unknown-linux-gnu -mattr=+sse,sse2,+bmi       < %s | FileCheck %s --check-prefixes=CHECK,X64,X64-BMI,X64-BMI1
; RUN: llc -mtriple=x86_64-unknown-linux-gnu -mattr=+sse,sse2,+bmi,+bmi2 < %s | FileCheck %s --check-prefixes=CHECK,X64,X64-BMI,X64-BMI12

; We are looking for the following pattern here:
;   (X & (C << Y)) ==/!= 0
; It may be optimal to hoist the constant:
;   ((X l>> Y) & C) ==/!= 0

;------------------------------------------------------------------------------;
; A few scalar test
;------------------------------------------------------------------------------;

; i8 scalar

define i1 @scalar_i8_signbit_eq(i8 %x, i8 %y) nounwind {
; X86-LABEL: scalar_i8_signbit_eq:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movb $-128, %al
; X86-NEXT:    shlb %cl, %al
; X86-NEXT:    testb %al, {{[0-9]+}}(%esp)
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: scalar_i8_signbit_eq:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movb $-128, %al
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    shlb %cl, %al
; X64-NEXT:    testb %dil, %al
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %t0 = shl i8 128, %y
  %t1 = and i8 %t0, %x
  %res = icmp eq i8 %t1, 0
  ret i1 %res
}

define i1 @scalar_i8_lowestbit_eq(i8 %x, i8 %y) nounwind {
; X86-LABEL: scalar_i8_lowestbit_eq:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    btl %eax, %ecx
; X86-NEXT:    setae %al
; X86-NEXT:    retl
;
; X64-LABEL: scalar_i8_lowestbit_eq:
; X64:       # %bb.0:
; X64-NEXT:    btl %esi, %edi
; X64-NEXT:    setae %al
; X64-NEXT:    retq
  %t0 = shl i8 1, %y
  %t1 = and i8 %t0, %x
  %res = icmp eq i8 %t1, 0
  ret i1 %res
}

define i1 @scalar_i8_bitsinmiddle_eq(i8 %x, i8 %y) nounwind {
; X86-LABEL: scalar_i8_bitsinmiddle_eq:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movb $24, %al
; X86-NEXT:    shlb %cl, %al
; X86-NEXT:    testb %al, {{[0-9]+}}(%esp)
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: scalar_i8_bitsinmiddle_eq:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movb $24, %al
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    shlb %cl, %al
; X64-NEXT:    testb %dil, %al
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %t0 = shl i8 24, %y
  %t1 = and i8 %t0, %x
  %res = icmp eq i8 %t1, 0
  ret i1 %res
}

; i16 scalar

define i1 @scalar_i16_signbit_eq(i16 %x, i16 %y) nounwind {
; X86-NOBMI-LABEL: scalar_i16_signbit_eq:
; X86-NOBMI:       # %bb.0:
; X86-NOBMI-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NOBMI-NEXT:    movl $-32768, %eax # imm = 0x8000
; X86-NOBMI-NEXT:    shll %cl, %eax
; X86-NOBMI-NEXT:    testw %ax, {{[0-9]+}}(%esp)
; X86-NOBMI-NEXT:    sete %al
; X86-NOBMI-NEXT:    retl
;
; X86-BMI1-LABEL: scalar_i16_signbit_eq:
; X86-BMI1:       # %bb.0:
; X86-BMI1-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-BMI1-NEXT:    movl $-32768, %eax # imm = 0x8000
; X86-BMI1-NEXT:    shll %cl, %eax
; X86-BMI1-NEXT:    testw %ax, {{[0-9]+}}(%esp)
; X86-BMI1-NEXT:    sete %al
; X86-BMI1-NEXT:    retl
;
; X86-BMI12-LABEL: scalar_i16_signbit_eq:
; X86-BMI12:       # %bb.0:
; X86-BMI12-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-BMI12-NEXT:    movl $-32768, %ecx # imm = 0x8000
; X86-BMI12-NEXT:    shlxl %eax, %ecx, %eax
; X86-BMI12-NEXT:    testw %ax, {{[0-9]+}}(%esp)
; X86-BMI12-NEXT:    sete %al
; X86-BMI12-NEXT:    retl
;
; X64-NOBMI-LABEL: scalar_i16_signbit_eq:
; X64-NOBMI:       # %bb.0:
; X64-NOBMI-NEXT:    movl %esi, %ecx
; X64-NOBMI-NEXT:    movl $-32768, %eax # imm = 0x8000
; X64-NOBMI-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NOBMI-NEXT:    shll %cl, %eax
; X64-NOBMI-NEXT:    testw %di, %ax
; X64-NOBMI-NEXT:    sete %al
; X64-NOBMI-NEXT:    retq
;
; X64-BMI1-LABEL: scalar_i16_signbit_eq:
; X64-BMI1:       # %bb.0:
; X64-BMI1-NEXT:    movl %esi, %ecx
; X64-BMI1-NEXT:    movl $-32768, %eax # imm = 0x8000
; X64-BMI1-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-BMI1-NEXT:    shll %cl, %eax
; X64-BMI1-NEXT:    testw %di, %ax
; X64-BMI1-NEXT:    sete %al
; X64-BMI1-NEXT:    retq
;
; X64-BMI12-LABEL: scalar_i16_signbit_eq:
; X64-BMI12:       # %bb.0:
; X64-BMI12-NEXT:    movl $-32768, %eax # imm = 0x8000
; X64-BMI12-NEXT:    shlxl %esi, %eax, %eax
; X64-BMI12-NEXT:    testw %di, %ax
; X64-BMI12-NEXT:    sete %al
; X64-BMI12-NEXT:    retq
  %t0 = shl i16 32768, %y
  %t1 = and i16 %t0, %x
  %res = icmp eq i16 %t1, 0
  ret i1 %res
}

define i1 @scalar_i16_lowestbit_eq(i16 %x, i16 %y) nounwind {
; X86-LABEL: scalar_i16_lowestbit_eq:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    btl %eax, %ecx
; X86-NEXT:    setae %al
; X86-NEXT:    retl
;
; X64-LABEL: scalar_i16_lowestbit_eq:
; X64:       # %bb.0:
; X64-NEXT:    btl %esi, %edi
; X64-NEXT:    setae %al
; X64-NEXT:    retq
  %t0 = shl i16 1, %y
  %t1 = and i16 %t0, %x
  %res = icmp eq i16 %t1, 0
  ret i1 %res
}

define i1 @scalar_i16_bitsinmiddle_eq(i16 %x, i16 %y) nounwind {
; X86-NOBMI-LABEL: scalar_i16_bitsinmiddle_eq:
; X86-NOBMI:       # %bb.0:
; X86-NOBMI-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NOBMI-NEXT:    movl $4080, %eax # imm = 0xFF0
; X86-NOBMI-NEXT:    shll %cl, %eax
; X86-NOBMI-NEXT:    testw %ax, {{[0-9]+}}(%esp)
; X86-NOBMI-NEXT:    sete %al
; X86-NOBMI-NEXT:    retl
;
; X86-BMI1-LABEL: scalar_i16_bitsinmiddle_eq:
; X86-BMI1:       # %bb.0:
; X86-BMI1-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-BMI1-NEXT:    movl $4080, %eax # imm = 0xFF0
; X86-BMI1-NEXT:    shll %cl, %eax
; X86-BMI1-NEXT:    testw %ax, {{[0-9]+}}(%esp)
; X86-BMI1-NEXT:    sete %al
; X86-BMI1-NEXT:    retl
;
; X86-BMI12-LABEL: scalar_i16_bitsinmiddle_eq:
; X86-BMI12:       # %bb.0:
; X86-BMI12-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-BMI12-NEXT:    movl $4080, %ecx # imm = 0xFF0
; X86-BMI12-NEXT:    shlxl %eax, %ecx, %eax
; X86-BMI12-NEXT:    testw %ax, {{[0-9]+}}(%esp)
; X86-BMI12-NEXT:    sete %al
; X86-BMI12-NEXT:    retl
;
; X64-NOBMI-LABEL: scalar_i16_bitsinmiddle_eq:
; X64-NOBMI:       # %bb.0:
; X64-NOBMI-NEXT:    movl %esi, %ecx
; X64-NOBMI-NEXT:    movl $4080, %eax # imm = 0xFF0
; X64-NOBMI-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NOBMI-NEXT:    shll %cl, %eax
; X64-NOBMI-NEXT:    testw %di, %ax
; X64-NOBMI-NEXT:    sete %al
; X64-NOBMI-NEXT:    retq
;
; X64-BMI1-LABEL: scalar_i16_bitsinmiddle_eq:
; X64-BMI1:       # %bb.0:
; X64-BMI1-NEXT:    movl %esi, %ecx
; X64-BMI1-NEXT:    movl $4080, %eax # imm = 0xFF0
; X64-BMI1-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-BMI1-NEXT:    shll %cl, %eax
; X64-BMI1-NEXT:    testw %di, %ax
; X64-BMI1-NEXT:    sete %al
; X64-BMI1-NEXT:    retq
;
; X64-BMI12-LABEL: scalar_i16_bitsinmiddle_eq:
; X64-BMI12:       # %bb.0:
; X64-BMI12-NEXT:    movl $4080, %eax # imm = 0xFF0
; X64-BMI12-NEXT:    shlxl %esi, %eax, %eax
; X64-BMI12-NEXT:    testw %di, %ax
; X64-BMI12-NEXT:    sete %al
; X64-BMI12-NEXT:    retq
  %t0 = shl i16 4080, %y
  %t1 = and i16 %t0, %x
  %res = icmp eq i16 %t1, 0
  ret i1 %res
}

; i32 scalar

define i1 @scalar_i32_signbit_eq(i32 %x, i32 %y) nounwind {
; X86-NOBMI-LABEL: scalar_i32_signbit_eq:
; X86-NOBMI:       # %bb.0:
; X86-NOBMI-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NOBMI-NEXT:    movl $-2147483648, %eax # imm = 0x80000000
; X86-NOBMI-NEXT:    shll %cl, %eax
; X86-NOBMI-NEXT:    testl %eax, {{[0-9]+}}(%esp)
; X86-NOBMI-NEXT:    sete %al
; X86-NOBMI-NEXT:    retl
;
; X86-BMI1-LABEL: scalar_i32_signbit_eq:
; X86-BMI1:       # %bb.0:
; X86-BMI1-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-BMI1-NEXT:    movl $-2147483648, %eax # imm = 0x80000000
; X86-BMI1-NEXT:    shll %cl, %eax
; X86-BMI1-NEXT:    testl %eax, {{[0-9]+}}(%esp)
; X86-BMI1-NEXT:    sete %al
; X86-BMI1-NEXT:    retl
;
; X86-BMI12-LABEL: scalar_i32_signbit_eq:
; X86-BMI12:       # %bb.0:
; X86-BMI12-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-BMI12-NEXT:    movl $-2147483648, %ecx # imm = 0x80000000
; X86-BMI12-NEXT:    shlxl %eax, %ecx, %eax
; X86-BMI12-NEXT:    testl %eax, {{[0-9]+}}(%esp)
; X86-BMI12-NEXT:    sete %al
; X86-BMI12-NEXT:    retl
;
; X64-NOBMI-LABEL: scalar_i32_signbit_eq:
; X64-NOBMI:       # %bb.0:
; X64-NOBMI-NEXT:    movl %esi, %ecx
; X64-NOBMI-NEXT:    movl $-2147483648, %eax # imm = 0x80000000
; X64-NOBMI-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NOBMI-NEXT:    shll %cl, %eax
; X64-NOBMI-NEXT:    testl %edi, %eax
; X64-NOBMI-NEXT:    sete %al
; X64-NOBMI-NEXT:    retq
;
; X64-BMI1-LABEL: scalar_i32_signbit_eq:
; X64-BMI1:       # %bb.0:
; X64-BMI1-NEXT:    movl %esi, %ecx
; X64-BMI1-NEXT:    movl $-2147483648, %eax # imm = 0x80000000
; X64-BMI1-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-BMI1-NEXT:    shll %cl, %eax
; X64-BMI1-NEXT:    testl %edi, %eax
; X64-BMI1-NEXT:    sete %al
; X64-BMI1-NEXT:    retq
;
; X64-BMI12-LABEL: scalar_i32_signbit_eq:
; X64-BMI12:       # %bb.0:
; X64-BMI12-NEXT:    movl $-2147483648, %eax # imm = 0x80000000
; X64-BMI12-NEXT:    shlxl %esi, %eax, %eax
; X64-BMI12-NEXT:    testl %edi, %eax
; X64-BMI12-NEXT:    sete %al
; X64-BMI12-NEXT:    retq
  %t0 = shl i32 2147483648, %y
  %t1 = and i32 %t0, %x
  %res = icmp eq i32 %t1, 0
  ret i1 %res
}

define i1 @scalar_i32_lowestbit_eq(i32 %x, i32 %y) nounwind {
; X86-LABEL: scalar_i32_lowestbit_eq:
; X86:       # %bb.0:
; X86-NEXT:    movl {{[0-9]+}}(%esp), %eax
; X86-NEXT:    movl {{[0-9]+}}(%esp), %ecx
; X86-NEXT:    btl %ecx, %eax
; X86-NEXT:    setae %al
; X86-NEXT:    retl
;
; X64-LABEL: scalar_i32_lowestbit_eq:
; X64:       # %bb.0:
; X64-NEXT:    btl %esi, %edi
; X64-NEXT:    setae %al
; X64-NEXT:    retq
  %t0 = shl i32 1, %y
  %t1 = and i32 %t0, %x
  %res = icmp eq i32 %t1, 0
  ret i1 %res
}

define i1 @scalar_i32_bitsinmiddle_eq(i32 %x, i32 %y) nounwind {
; X86-NOBMI-LABEL: scalar_i32_bitsinmiddle_eq:
; X86-NOBMI:       # %bb.0:
; X86-NOBMI-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NOBMI-NEXT:    movl $16776960, %eax # imm = 0xFFFF00
; X86-NOBMI-NEXT:    shll %cl, %eax
; X86-NOBMI-NEXT:    testl %eax, {{[0-9]+}}(%esp)
; X86-NOBMI-NEXT:    sete %al
; X86-NOBMI-NEXT:    retl
;
; X86-BMI1-LABEL: scalar_i32_bitsinmiddle_eq:
; X86-BMI1:       # %bb.0:
; X86-BMI1-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-BMI1-NEXT:    movl $16776960, %eax # imm = 0xFFFF00
; X86-BMI1-NEXT:    shll %cl, %eax
; X86-BMI1-NEXT:    testl %eax, {{[0-9]+}}(%esp)
; X86-BMI1-NEXT:    sete %al
; X86-BMI1-NEXT:    retl
;
; X86-BMI12-LABEL: scalar_i32_bitsinmiddle_eq:
; X86-BMI12:       # %bb.0:
; X86-BMI12-NEXT:    movb {{[0-9]+}}(%esp), %al
; X86-BMI12-NEXT:    movl $16776960, %ecx # imm = 0xFFFF00
; X86-BMI12-NEXT:    shlxl %eax, %ecx, %eax
; X86-BMI12-NEXT:    testl %eax, {{[0-9]+}}(%esp)
; X86-BMI12-NEXT:    sete %al
; X86-BMI12-NEXT:    retl
;
; X64-NOBMI-LABEL: scalar_i32_bitsinmiddle_eq:
; X64-NOBMI:       # %bb.0:
; X64-NOBMI-NEXT:    movl %esi, %ecx
; X64-NOBMI-NEXT:    movl $16776960, %eax # imm = 0xFFFF00
; X64-NOBMI-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NOBMI-NEXT:    shll %cl, %eax
; X64-NOBMI-NEXT:    testl %edi, %eax
; X64-NOBMI-NEXT:    sete %al
; X64-NOBMI-NEXT:    retq
;
; X64-BMI1-LABEL: scalar_i32_bitsinmiddle_eq:
; X64-BMI1:       # %bb.0:
; X64-BMI1-NEXT:    movl %esi, %ecx
; X64-BMI1-NEXT:    movl $16776960, %eax # imm = 0xFFFF00
; X64-BMI1-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-BMI1-NEXT:    shll %cl, %eax
; X64-BMI1-NEXT:    testl %edi, %eax
; X64-BMI1-NEXT:    sete %al
; X64-BMI1-NEXT:    retq
;
; X64-BMI12-LABEL: scalar_i32_bitsinmiddle_eq:
; X64-BMI12:       # %bb.0:
; X64-BMI12-NEXT:    movl $16776960, %eax # imm = 0xFFFF00
; X64-BMI12-NEXT:    shlxl %esi, %eax, %eax
; X64-BMI12-NEXT:    testl %edi, %eax
; X64-BMI12-NEXT:    sete %al
; X64-BMI12-NEXT:    retq
  %t0 = shl i32 16776960, %y
  %t1 = and i32 %t0, %x
  %res = icmp eq i32 %t1, 0
  ret i1 %res
}

; i64 scalar

define i1 @scalar_i64_signbit_eq(i64 %x, i64 %y) nounwind {
; X86-LABEL: scalar_i64_signbit_eq:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    xorl %eax, %eax
; X86-NEXT:    movl $-2147483648, %edx # imm = 0x80000000
; X86-NEXT:    shldl %cl, %eax, %edx
; X86-NEXT:    testb $32, %cl
; X86-NEXT:    cmovnel %eax, %edx
; X86-NEXT:    andl {{[0-9]+}}(%esp), %edx
; X86-NEXT:    orl $0, %edx
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-NOBMI-LABEL: scalar_i64_signbit_eq:
; X64-NOBMI:       # %bb.0:
; X64-NOBMI-NEXT:    movq %rsi, %rcx
; X64-NOBMI-NEXT:    movabsq $-9223372036854775808, %rax # imm = 0x8000000000000000
; X64-NOBMI-NEXT:    # kill: def $cl killed $cl killed $rcx
; X64-NOBMI-NEXT:    shlq %cl, %rax
; X64-NOBMI-NEXT:    testq %rdi, %rax
; X64-NOBMI-NEXT:    sete %al
; X64-NOBMI-NEXT:    retq
;
; X64-BMI1-LABEL: scalar_i64_signbit_eq:
; X64-BMI1:       # %bb.0:
; X64-BMI1-NEXT:    movq %rsi, %rcx
; X64-BMI1-NEXT:    movabsq $-9223372036854775808, %rax # imm = 0x8000000000000000
; X64-BMI1-NEXT:    # kill: def $cl killed $cl killed $rcx
; X64-BMI1-NEXT:    shlq %cl, %rax
; X64-BMI1-NEXT:    testq %rdi, %rax
; X64-BMI1-NEXT:    sete %al
; X64-BMI1-NEXT:    retq
;
; X64-BMI12-LABEL: scalar_i64_signbit_eq:
; X64-BMI12:       # %bb.0:
; X64-BMI12-NEXT:    movabsq $-9223372036854775808, %rax # imm = 0x8000000000000000
; X64-BMI12-NEXT:    shlxq %rsi, %rax, %rax
; X64-BMI12-NEXT:    testq %rdi, %rax
; X64-BMI12-NEXT:    sete %al
; X64-BMI12-NEXT:    retq
  %t0 = shl i64 9223372036854775808, %y
  %t1 = and i64 %t0, %x
  %res = icmp eq i64 %t1, 0
  ret i1 %res
}

define i1 @scalar_i64_lowestbit_eq(i64 %x, i64 %y) nounwind {
; X86-NOBMI-LABEL: scalar_i64_lowestbit_eq:
; X86-NOBMI:       # %bb.0:
; X86-NOBMI-NEXT:    pushl %esi
; X86-NOBMI-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NOBMI-NEXT:    movl $1, %eax
; X86-NOBMI-NEXT:    xorl %edx, %edx
; X86-NOBMI-NEXT:    xorl %esi, %esi
; X86-NOBMI-NEXT:    shldl %cl, %eax, %esi
; X86-NOBMI-NEXT:    shll %cl, %eax
; X86-NOBMI-NEXT:    testb $32, %cl
; X86-NOBMI-NEXT:    cmovnel %eax, %esi
; X86-NOBMI-NEXT:    cmovnel %edx, %eax
; X86-NOBMI-NEXT:    andl {{[0-9]+}}(%esp), %esi
; X86-NOBMI-NEXT:    andl {{[0-9]+}}(%esp), %eax
; X86-NOBMI-NEXT:    orl %esi, %eax
; X86-NOBMI-NEXT:    sete %al
; X86-NOBMI-NEXT:    popl %esi
; X86-NOBMI-NEXT:    retl
;
; X86-BMI1-LABEL: scalar_i64_lowestbit_eq:
; X86-BMI1:       # %bb.0:
; X86-BMI1-NEXT:    pushl %esi
; X86-BMI1-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-BMI1-NEXT:    movl $1, %eax
; X86-BMI1-NEXT:    xorl %edx, %edx
; X86-BMI1-NEXT:    xorl %esi, %esi
; X86-BMI1-NEXT:    shldl %cl, %eax, %esi
; X86-BMI1-NEXT:    shll %cl, %eax
; X86-BMI1-NEXT:    testb $32, %cl
; X86-BMI1-NEXT:    cmovnel %eax, %esi
; X86-BMI1-NEXT:    cmovnel %edx, %eax
; X86-BMI1-NEXT:    andl {{[0-9]+}}(%esp), %esi
; X86-BMI1-NEXT:    andl {{[0-9]+}}(%esp), %eax
; X86-BMI1-NEXT:    orl %esi, %eax
; X86-BMI1-NEXT:    sete %al
; X86-BMI1-NEXT:    popl %esi
; X86-BMI1-NEXT:    retl
;
; X86-BMI12-LABEL: scalar_i64_lowestbit_eq:
; X86-BMI12:       # %bb.0:
; X86-BMI12-NEXT:    pushl %esi
; X86-BMI12-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-BMI12-NEXT:    movl $1, %eax
; X86-BMI12-NEXT:    xorl %edx, %edx
; X86-BMI12-NEXT:    xorl %esi, %esi
; X86-BMI12-NEXT:    shldl %cl, %eax, %esi
; X86-BMI12-NEXT:    shlxl %ecx, %eax, %eax
; X86-BMI12-NEXT:    testb $32, %cl
; X86-BMI12-NEXT:    cmovnel %eax, %esi
; X86-BMI12-NEXT:    cmovnel %edx, %eax
; X86-BMI12-NEXT:    andl {{[0-9]+}}(%esp), %esi
; X86-BMI12-NEXT:    andl {{[0-9]+}}(%esp), %eax
; X86-BMI12-NEXT:    orl %esi, %eax
; X86-BMI12-NEXT:    sete %al
; X86-BMI12-NEXT:    popl %esi
; X86-BMI12-NEXT:    retl
;
; X64-LABEL: scalar_i64_lowestbit_eq:
; X64:       # %bb.0:
; X64-NEXT:    btq %rsi, %rdi
; X64-NEXT:    setae %al
; X64-NEXT:    retq
  %t0 = shl i64 1, %y
  %t1 = and i64 %t0, %x
  %res = icmp eq i64 %t1, 0
  ret i1 %res
}

define i1 @scalar_i64_bitsinmiddle_eq(i64 %x, i64 %y) nounwind {
; X86-NOBMI-LABEL: scalar_i64_bitsinmiddle_eq:
; X86-NOBMI:       # %bb.0:
; X86-NOBMI-NEXT:    pushl %esi
; X86-NOBMI-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NOBMI-NEXT:    movl $-65536, %eax # imm = 0xFFFF0000
; X86-NOBMI-NEXT:    movl $65535, %edx # imm = 0xFFFF
; X86-NOBMI-NEXT:    shldl %cl, %eax, %edx
; X86-NOBMI-NEXT:    shll %cl, %eax
; X86-NOBMI-NEXT:    xorl %esi, %esi
; X86-NOBMI-NEXT:    testb $32, %cl
; X86-NOBMI-NEXT:    cmovnel %eax, %edx
; X86-NOBMI-NEXT:    cmovel %eax, %esi
; X86-NOBMI-NEXT:    andl {{[0-9]+}}(%esp), %edx
; X86-NOBMI-NEXT:    andl {{[0-9]+}}(%esp), %esi
; X86-NOBMI-NEXT:    orl %edx, %esi
; X86-NOBMI-NEXT:    sete %al
; X86-NOBMI-NEXT:    popl %esi
; X86-NOBMI-NEXT:    retl
;
; X86-BMI1-LABEL: scalar_i64_bitsinmiddle_eq:
; X86-BMI1:       # %bb.0:
; X86-BMI1-NEXT:    pushl %esi
; X86-BMI1-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-BMI1-NEXT:    movl $-65536, %eax # imm = 0xFFFF0000
; X86-BMI1-NEXT:    movl $65535, %edx # imm = 0xFFFF
; X86-BMI1-NEXT:    shldl %cl, %eax, %edx
; X86-BMI1-NEXT:    shll %cl, %eax
; X86-BMI1-NEXT:    xorl %esi, %esi
; X86-BMI1-NEXT:    testb $32, %cl
; X86-BMI1-NEXT:    cmovnel %eax, %edx
; X86-BMI1-NEXT:    cmovel %eax, %esi
; X86-BMI1-NEXT:    andl {{[0-9]+}}(%esp), %edx
; X86-BMI1-NEXT:    andl {{[0-9]+}}(%esp), %esi
; X86-BMI1-NEXT:    orl %edx, %esi
; X86-BMI1-NEXT:    sete %al
; X86-BMI1-NEXT:    popl %esi
; X86-BMI1-NEXT:    retl
;
; X86-BMI12-LABEL: scalar_i64_bitsinmiddle_eq:
; X86-BMI12:       # %bb.0:
; X86-BMI12-NEXT:    pushl %esi
; X86-BMI12-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-BMI12-NEXT:    movl $-65536, %eax # imm = 0xFFFF0000
; X86-BMI12-NEXT:    movl $65535, %edx # imm = 0xFFFF
; X86-BMI12-NEXT:    shldl %cl, %eax, %edx
; X86-BMI12-NEXT:    shlxl %ecx, %eax, %eax
; X86-BMI12-NEXT:    xorl %esi, %esi
; X86-BMI12-NEXT:    testb $32, %cl
; X86-BMI12-NEXT:    cmovnel %eax, %edx
; X86-BMI12-NEXT:    cmovel %eax, %esi
; X86-BMI12-NEXT:    andl {{[0-9]+}}(%esp), %edx
; X86-BMI12-NEXT:    andl {{[0-9]+}}(%esp), %esi
; X86-BMI12-NEXT:    orl %edx, %esi
; X86-BMI12-NEXT:    sete %al
; X86-BMI12-NEXT:    popl %esi
; X86-BMI12-NEXT:    retl
;
; X64-NOBMI-LABEL: scalar_i64_bitsinmiddle_eq:
; X64-NOBMI:       # %bb.0:
; X64-NOBMI-NEXT:    movq %rsi, %rcx
; X64-NOBMI-NEXT:    movabsq $281474976645120, %rax # imm = 0xFFFFFFFF0000
; X64-NOBMI-NEXT:    # kill: def $cl killed $cl killed $rcx
; X64-NOBMI-NEXT:    shlq %cl, %rax
; X64-NOBMI-NEXT:    testq %rdi, %rax
; X64-NOBMI-NEXT:    sete %al
; X64-NOBMI-NEXT:    retq
;
; X64-BMI1-LABEL: scalar_i64_bitsinmiddle_eq:
; X64-BMI1:       # %bb.0:
; X64-BMI1-NEXT:    movq %rsi, %rcx
; X64-BMI1-NEXT:    movabsq $281474976645120, %rax # imm = 0xFFFFFFFF0000
; X64-BMI1-NEXT:    # kill: def $cl killed $cl killed $rcx
; X64-BMI1-NEXT:    shlq %cl, %rax
; X64-BMI1-NEXT:    testq %rdi, %rax
; X64-BMI1-NEXT:    sete %al
; X64-BMI1-NEXT:    retq
;
; X64-BMI12-LABEL: scalar_i64_bitsinmiddle_eq:
; X64-BMI12:       # %bb.0:
; X64-BMI12-NEXT:    movabsq $281474976645120, %rax # imm = 0xFFFFFFFF0000
; X64-BMI12-NEXT:    shlxq %rsi, %rax, %rax
; X64-BMI12-NEXT:    testq %rdi, %rax
; X64-BMI12-NEXT:    sete %al
; X64-BMI12-NEXT:    retq
  %t0 = shl i64 281474976645120, %y
  %t1 = and i64 %t0, %x
  %res = icmp eq i64 %t1, 0
  ret i1 %res
}

;------------------------------------------------------------------------------;
; A few trivial vector tests
;------------------------------------------------------------------------------;

define <4 x i1> @vec_4xi32_splat_eq(<4 x i32> %x, <4 x i32> %y) nounwind {
; X86-LABEL: vec_4xi32_splat_eq:
; X86:       # %bb.0:
; X86-NEXT:    pslld $23, %xmm1
; X86-NEXT:    paddd {{\.LCPI.*}}, %xmm1
; X86-NEXT:    cvttps2dq %xmm1, %xmm1
; X86-NEXT:    movdqa {{.*#+}} xmm2 = [1,1,1,1]
; X86-NEXT:    pshufd {{.*#+}} xmm3 = xmm1[1,1,3,3]
; X86-NEXT:    pmuludq %xmm2, %xmm3
; X86-NEXT:    pmuludq %xmm1, %xmm2
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm3[0,2,2,3]
; X86-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
; X86-NEXT:    pand %xmm1, %xmm0
; X86-NEXT:    pxor %xmm1, %xmm1
; X86-NEXT:    pcmpeqd %xmm1, %xmm0
; X86-NEXT:    retl
;
; X64-LABEL: vec_4xi32_splat_eq:
; X64:       # %bb.0:
; X64-NEXT:    pslld $23, %xmm1
; X64-NEXT:    paddd {{.*}}(%rip), %xmm1
; X64-NEXT:    cvttps2dq %xmm1, %xmm1
; X64-NEXT:    movdqa {{.*#+}} xmm2 = [1,1,1,1]
; X64-NEXT:    pshufd {{.*#+}} xmm3 = xmm1[1,1,3,3]
; X64-NEXT:    pmuludq %xmm2, %xmm3
; X64-NEXT:    pmuludq %xmm1, %xmm2
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X64-NEXT:    pshufd {{.*#+}} xmm2 = xmm3[0,2,2,3]
; X64-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
; X64-NEXT:    pand %xmm1, %xmm0
; X64-NEXT:    pxor %xmm1, %xmm1
; X64-NEXT:    pcmpeqd %xmm1, %xmm0
; X64-NEXT:    retq
  %t0 = shl <4 x i32> <i32 1, i32 1, i32 1, i32 1>, %y
  %t1 = and <4 x i32> %t0, %x
  %res = icmp eq <4 x i32> %t1, <i32 0, i32 0, i32 0, i32 0>
  ret <4 x i1> %res
}

define <4 x i1> @vec_4xi32_nonsplat_eq(<4 x i32> %x, <4 x i32> %y) nounwind {
; X86-LABEL: vec_4xi32_nonsplat_eq:
; X86:       # %bb.0:
; X86-NEXT:    pslld $23, %xmm1
; X86-NEXT:    paddd {{\.LCPI.*}}, %xmm1
; X86-NEXT:    cvttps2dq %xmm1, %xmm1
; X86-NEXT:    movdqa {{.*#+}} xmm2 = [0,1,16776960,2147483648]
; X86-NEXT:    pshufd {{.*#+}} xmm3 = xmm2[1,1,3,3]
; X86-NEXT:    pmuludq %xmm1, %xmm2
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm2[0,2,2,3]
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[1,1,3,3]
; X86-NEXT:    pmuludq %xmm3, %xmm1
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,2,2,3]
; X86-NEXT:    punpckldq {{.*#+}} xmm2 = xmm2[0],xmm1[0],xmm2[1],xmm1[1]
; X86-NEXT:    pand %xmm2, %xmm0
; X86-NEXT:    pxor %xmm1, %xmm1
; X86-NEXT:    pcmpeqd %xmm1, %xmm0
; X86-NEXT:    retl
;
; X64-LABEL: vec_4xi32_nonsplat_eq:
; X64:       # %bb.0:
; X64-NEXT:    pslld $23, %xmm1
; X64-NEXT:    paddd {{.*}}(%rip), %xmm1
; X64-NEXT:    cvttps2dq %xmm1, %xmm1
; X64-NEXT:    movdqa {{.*#+}} xmm2 = [0,1,16776960,2147483648]
; X64-NEXT:    pshufd {{.*#+}} xmm3 = xmm2[1,1,3,3]
; X64-NEXT:    pmuludq %xmm1, %xmm2
; X64-NEXT:    pshufd {{.*#+}} xmm2 = xmm2[0,2,2,3]
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[1,1,3,3]
; X64-NEXT:    pmuludq %xmm3, %xmm1
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm1[0,2,2,3]
; X64-NEXT:    punpckldq {{.*#+}} xmm2 = xmm2[0],xmm1[0],xmm2[1],xmm1[1]
; X64-NEXT:    pand %xmm2, %xmm0
; X64-NEXT:    pxor %xmm1, %xmm1
; X64-NEXT:    pcmpeqd %xmm1, %xmm0
; X64-NEXT:    retq
  %t0 = shl <4 x i32> <i32 0, i32 1, i32 16776960, i32 2147483648>, %y
  %t1 = and <4 x i32> %t0, %x
  %res = icmp eq <4 x i32> %t1, <i32 0, i32 0, i32 0, i32 0>
  ret <4 x i1> %res
}

define <4 x i1> @vec_4xi32_nonsplat_undef0_eq(<4 x i32> %x, <4 x i32> %y) nounwind {
; X86-LABEL: vec_4xi32_nonsplat_undef0_eq:
; X86:       # %bb.0:
; X86-NEXT:    pslld $23, %xmm1
; X86-NEXT:    paddd {{\.LCPI.*}}, %xmm1
; X86-NEXT:    cvttps2dq %xmm1, %xmm1
; X86-NEXT:    movdqa {{.*#+}} xmm2 = [1,1,1,1]
; X86-NEXT:    pshufd {{.*#+}} xmm3 = xmm1[1,1,3,3]
; X86-NEXT:    pmuludq %xmm2, %xmm3
; X86-NEXT:    pmuludq %xmm1, %xmm2
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm3[0,2,2,3]
; X86-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
; X86-NEXT:    pand %xmm1, %xmm0
; X86-NEXT:    pxor %xmm1, %xmm1
; X86-NEXT:    pcmpeqd %xmm1, %xmm0
; X86-NEXT:    retl
;
; X64-LABEL: vec_4xi32_nonsplat_undef0_eq:
; X64:       # %bb.0:
; X64-NEXT:    pslld $23, %xmm1
; X64-NEXT:    paddd {{.*}}(%rip), %xmm1
; X64-NEXT:    cvttps2dq %xmm1, %xmm1
; X64-NEXT:    movdqa {{.*#+}} xmm2 = [1,1,1,1]
; X64-NEXT:    pshufd {{.*#+}} xmm3 = xmm1[1,1,3,3]
; X64-NEXT:    pmuludq %xmm2, %xmm3
; X64-NEXT:    pmuludq %xmm1, %xmm2
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X64-NEXT:    pshufd {{.*#+}} xmm2 = xmm3[0,2,2,3]
; X64-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
; X64-NEXT:    pand %xmm1, %xmm0
; X64-NEXT:    pxor %xmm1, %xmm1
; X64-NEXT:    pcmpeqd %xmm1, %xmm0
; X64-NEXT:    retq
  %t0 = shl <4 x i32> <i32 1, i32 1, i32 undef, i32 1>, %y
  %t1 = and <4 x i32> %t0, %x
  %res = icmp eq <4 x i32> %t1, <i32 0, i32 0, i32 0, i32 0>
  ret <4 x i1> %res
}
define <4 x i1> @vec_4xi32_nonsplat_undef1_eq(<4 x i32> %x, <4 x i32> %y) nounwind {
; X86-LABEL: vec_4xi32_nonsplat_undef1_eq:
; X86:       # %bb.0:
; X86-NEXT:    pslld $23, %xmm1
; X86-NEXT:    paddd {{\.LCPI.*}}, %xmm1
; X86-NEXT:    cvttps2dq %xmm1, %xmm1
; X86-NEXT:    movdqa {{.*#+}} xmm2 = [1,1,1,1]
; X86-NEXT:    pshufd {{.*#+}} xmm3 = xmm1[1,1,3,3]
; X86-NEXT:    pmuludq %xmm2, %xmm3
; X86-NEXT:    pmuludq %xmm1, %xmm2
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm3[0,2,2,3]
; X86-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
; X86-NEXT:    pand %xmm1, %xmm0
; X86-NEXT:    pxor %xmm1, %xmm1
; X86-NEXT:    pcmpeqd %xmm1, %xmm0
; X86-NEXT:    retl
;
; X64-LABEL: vec_4xi32_nonsplat_undef1_eq:
; X64:       # %bb.0:
; X64-NEXT:    pslld $23, %xmm1
; X64-NEXT:    paddd {{.*}}(%rip), %xmm1
; X64-NEXT:    cvttps2dq %xmm1, %xmm1
; X64-NEXT:    movdqa {{.*#+}} xmm2 = [1,1,1,1]
; X64-NEXT:    pshufd {{.*#+}} xmm3 = xmm1[1,1,3,3]
; X64-NEXT:    pmuludq %xmm2, %xmm3
; X64-NEXT:    pmuludq %xmm1, %xmm2
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X64-NEXT:    pshufd {{.*#+}} xmm2 = xmm3[0,2,2,3]
; X64-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
; X64-NEXT:    pand %xmm1, %xmm0
; X64-NEXT:    pxor %xmm1, %xmm1
; X64-NEXT:    pcmpeqd %xmm1, %xmm0
; X64-NEXT:    retq
  %t0 = shl <4 x i32> <i32 1, i32 1, i32 1, i32 1>, %y
  %t1 = and <4 x i32> %t0, %x
  %res = icmp eq <4 x i32> %t1, <i32 0, i32 0, i32 undef, i32 0>
  ret <4 x i1> %res
}
define <4 x i1> @vec_4xi32_nonsplat_undef2_eq(<4 x i32> %x, <4 x i32> %y) nounwind {
; X86-LABEL: vec_4xi32_nonsplat_undef2_eq:
; X86:       # %bb.0:
; X86-NEXT:    pslld $23, %xmm1
; X86-NEXT:    paddd {{\.LCPI.*}}, %xmm1
; X86-NEXT:    cvttps2dq %xmm1, %xmm1
; X86-NEXT:    movdqa {{.*#+}} xmm2 = [1,1,1,1]
; X86-NEXT:    pshufd {{.*#+}} xmm3 = xmm1[1,1,3,3]
; X86-NEXT:    pmuludq %xmm2, %xmm3
; X86-NEXT:    pmuludq %xmm1, %xmm2
; X86-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X86-NEXT:    pshufd {{.*#+}} xmm2 = xmm3[0,2,2,3]
; X86-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
; X86-NEXT:    pand %xmm1, %xmm0
; X86-NEXT:    pxor %xmm1, %xmm1
; X86-NEXT:    pcmpeqd %xmm1, %xmm0
; X86-NEXT:    retl
;
; X64-LABEL: vec_4xi32_nonsplat_undef2_eq:
; X64:       # %bb.0:
; X64-NEXT:    pslld $23, %xmm1
; X64-NEXT:    paddd {{.*}}(%rip), %xmm1
; X64-NEXT:    cvttps2dq %xmm1, %xmm1
; X64-NEXT:    movdqa {{.*#+}} xmm2 = [1,1,1,1]
; X64-NEXT:    pshufd {{.*#+}} xmm3 = xmm1[1,1,3,3]
; X64-NEXT:    pmuludq %xmm2, %xmm3
; X64-NEXT:    pmuludq %xmm1, %xmm2
; X64-NEXT:    pshufd {{.*#+}} xmm1 = xmm2[0,2,2,3]
; X64-NEXT:    pshufd {{.*#+}} xmm2 = xmm3[0,2,2,3]
; X64-NEXT:    punpckldq {{.*#+}} xmm1 = xmm1[0],xmm2[0],xmm1[1],xmm2[1]
; X64-NEXT:    pand %xmm1, %xmm0
; X64-NEXT:    pxor %xmm1, %xmm1
; X64-NEXT:    pcmpeqd %xmm1, %xmm0
; X64-NEXT:    retq
  %t0 = shl <4 x i32> <i32 1, i32 1, i32 undef, i32 1>, %y
  %t1 = and <4 x i32> %t0, %x
  %res = icmp eq <4 x i32> %t1, <i32 0, i32 0, i32 undef, i32 0>
  ret <4 x i1> %res
}

;------------------------------------------------------------------------------;
; A special tests
;------------------------------------------------------------------------------;

define i1 @scalar_i8_signbit_ne(i8 %x, i8 %y) nounwind {
; X86-LABEL: scalar_i8_signbit_ne:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movb $-128, %al
; X86-NEXT:    shlb %cl, %al
; X86-NEXT:    testb %al, {{[0-9]+}}(%esp)
; X86-NEXT:    setne %al
; X86-NEXT:    retl
;
; X64-LABEL: scalar_i8_signbit_ne:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movb $-128, %al
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    shlb %cl, %al
; X64-NEXT:    testb %dil, %al
; X64-NEXT:    setne %al
; X64-NEXT:    retq
  %t0 = shl i8 128, %y
  %t1 = and i8 %t0, %x
  %res = icmp ne i8 %t1, 0 ;  we are perfectly happy with 'ne' predicate
  ret i1 %res
}

;------------------------------------------------------------------------------;
; A few negative tests
;------------------------------------------------------------------------------;

define i1 @negative_scalar_i8_bitsinmiddle_slt(i8 %x, i8 %y) nounwind {
; X86-LABEL: negative_scalar_i8_bitsinmiddle_slt:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movb $24, %al
; X86-NEXT:    shlb %cl, %al
; X86-NEXT:    andb {{[0-9]+}}(%esp), %al
; X86-NEXT:    shrb $7, %al
; X86-NEXT:    retl
;
; X64-LABEL: negative_scalar_i8_bitsinmiddle_slt:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movb $24, %al
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    shlb %cl, %al
; X64-NEXT:    andb %dil, %al
; X64-NEXT:    shrb $7, %al
; X64-NEXT:    retq
  %t0 = shl i8 24, %y
  %t1 = and i8 %t0, %x
  %res = icmp slt i8 %t1, 0
  ret i1 %res
}

define i1 @scalar_i8_signbit_eq_with_nonzero(i8 %x, i8 %y) nounwind {
; X86-LABEL: scalar_i8_signbit_eq_with_nonzero:
; X86:       # %bb.0:
; X86-NEXT:    movb {{[0-9]+}}(%esp), %cl
; X86-NEXT:    movb $-128, %al
; X86-NEXT:    shlb %cl, %al
; X86-NEXT:    andb {{[0-9]+}}(%esp), %al
; X86-NEXT:    cmpb $1, %al
; X86-NEXT:    sete %al
; X86-NEXT:    retl
;
; X64-LABEL: scalar_i8_signbit_eq_with_nonzero:
; X64:       # %bb.0:
; X64-NEXT:    movl %esi, %ecx
; X64-NEXT:    movb $-128, %al
; X64-NEXT:    # kill: def $cl killed $cl killed $ecx
; X64-NEXT:    shlb %cl, %al
; X64-NEXT:    andb %dil, %al
; X64-NEXT:    cmpb $1, %al
; X64-NEXT:    sete %al
; X64-NEXT:    retq
  %t0 = shl i8 128, %y
  %t1 = and i8 %t0, %x
  %res = icmp eq i8 %t1, 1 ; should be comparing with 0
  ret i1 %res
}
