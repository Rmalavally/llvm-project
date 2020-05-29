; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -S -sroa < %s | FileCheck %s

%pair = type { i32, i32 }

define i32 @test_sroa_select_gep(i1 %cond) {
; CHECK-LABEL: @test_sroa_select_gep(
; CHECK-NEXT:  bb:
; CHECK-NEXT:    [[LOAD_SROA_SPECULATED:%.*]] = select i1 [[COND:%.*]], i32 1, i32 2
; CHECK-NEXT:    ret i32 [[LOAD_SROA_SPECULATED]]
;
bb:
  %a = alloca %pair, align 4
  %b = alloca %pair, align 4
  %gep_a = getelementptr inbounds %pair, %pair* %a, i32 0, i32 1
  %gep_b = getelementptr inbounds %pair, %pair* %b, i32 0, i32 1
  store i32 1, i32* %gep_a, align 4
  store i32 2, i32* %gep_b, align 4
  %select = select i1 %cond, %pair* %a, %pair* %b
  %gep = getelementptr inbounds %pair, %pair* %select, i32 0, i32 1
  %load = load i32, i32* %gep, align 4
  ret i32 %load
}

define i32 @test_sroa_select_gep_non_inbound(i1 %cond) {
; CHECK-LABEL: @test_sroa_select_gep_non_inbound(
; CHECK-NEXT:  bb:
; CHECK-NEXT:    [[LOAD_SROA_SPECULATED:%.*]] = select i1 [[COND:%.*]], i32 1, i32 2
; CHECK-NEXT:    ret i32 [[LOAD_SROA_SPECULATED]]
;
bb:
  %a = alloca %pair, align 4
  %b = alloca %pair, align 4
  %gep_a = getelementptr %pair, %pair* %a, i32 0, i32 1
  %gep_b = getelementptr %pair, %pair* %b, i32 0, i32 1
  store i32 1, i32* %gep_a, align 4
  store i32 2, i32* %gep_b, align 4
  %select = select i1 %cond, %pair* %a, %pair* %b
  %gep = getelementptr %pair, %pair* %select, i32 0, i32 1
  %load = load i32, i32* %gep, align 4
  ret i32 %load
}

define i32 @test_sroa_select_gep_volatile_load(i1 %cond) {
; CHECK-LABEL: @test_sroa_select_gep_volatile_load(
; CHECK-NEXT:  bb:
; CHECK-NEXT:    [[A_SROA_0:%.*]] = alloca i32
; CHECK-NEXT:    [[A_SROA_2:%.*]] = alloca i32
; CHECK-NEXT:    [[B_SROA_0:%.*]] = alloca i32
; CHECK-NEXT:    [[B_SROA_2:%.*]] = alloca i32
; CHECK-NEXT:    store i32 11, i32* [[A_SROA_0]]
; CHECK-NEXT:    store i32 12, i32* [[B_SROA_0]]
; CHECK-NEXT:    store i32 21, i32* [[A_SROA_2]]
; CHECK-NEXT:    store i32 22, i32* [[B_SROA_2]]
; CHECK-NEXT:    [[SELECT_SROA_SEL:%.*]] = select i1 [[COND:%.*]], i32* [[A_SROA_0]], i32* [[B_SROA_0]]
; CHECK-NEXT:    [[LOAD1:%.*]] = load volatile i32, i32* [[SELECT_SROA_SEL]], align 4
; CHECK-NEXT:    [[SELECT_SROA_SEL3:%.*]] = select i1 [[COND]], i32* [[A_SROA_2]], i32* [[B_SROA_2]]
; CHECK-NEXT:    [[LOAD2:%.*]] = load volatile i32, i32* [[SELECT_SROA_SEL3]], align 4
; CHECK-NEXT:    [[ADD:%.*]] = add i32 [[LOAD1]], [[LOAD2]]
; CHECK-NEXT:    ret i32 [[ADD]]
;
bb:
  %a = alloca %pair, align 4
  %b = alloca %pair, align 4
  %gep_a0 = getelementptr inbounds %pair, %pair* %a, i32 0, i32 0
  %gep_b0 = getelementptr inbounds %pair, %pair* %b, i32 0, i32 0
  store i32 11, i32* %gep_a0, align 4
  store i32 12, i32* %gep_b0, align 4
  %gep_a1 = getelementptr inbounds %pair, %pair* %a, i32 0, i32 1
  %gep_b1 = getelementptr inbounds %pair, %pair* %b, i32 0, i32 1
  store i32 21, i32* %gep_a1, align 4
  store i32 22, i32* %gep_b1, align 4
  %select = select i1 %cond, %pair* %a, %pair* %b
  %gep1 = getelementptr inbounds %pair, %pair* %select, i32 0, i32 0
  %load1 = load volatile i32, i32* %gep1, align 4
  %gep2 = getelementptr inbounds %pair, %pair* %select, i32 0, i32 1
  %load2 = load volatile i32, i32* %gep2, align 4
  %add = add i32 %load1, %load2
  ret i32 %add
}

define i32 @test_sroa_select_gep_undef(i1 %cond) {
; CHECK-LABEL: @test_sroa_select_gep_undef(
; CHECK-NEXT:  bb:
; CHECK-NEXT:    [[A_SROA_0:%.*]] = alloca i32
; CHECK-NEXT:    [[SELECT_SROA_SEL:%.*]] = select i1 [[COND:%.*]], i32* [[A_SROA_0]], i32* undef
; CHECK-NEXT:    [[LOAD:%.*]] = load i32, i32* [[SELECT_SROA_SEL]], align 4
; CHECK-NEXT:    ret i32 [[LOAD]]
;
bb:
  %a = alloca %pair, align 4
  %select = select i1 %cond, %pair* %a, %pair* undef
  %gep = getelementptr inbounds %pair, %pair* %select, i32 0, i32 1
  %load = load i32, i32* %gep, align 4
  ret i32 %load
}

define i32 @test_sroa_gep_select_gep(i1 %cond) {
; CHECK-LABEL: @test_sroa_gep_select_gep(
; CHECK-NEXT:  bb:
; CHECK-NEXT:    [[A_SROA_0:%.*]] = alloca i32
; CHECK-NEXT:    [[B_SROA_0:%.*]] = alloca i32
; CHECK-NEXT:    store i32 1, i32* [[A_SROA_0]]
; CHECK-NEXT:    store i32 2, i32* [[B_SROA_0]]
; CHECK-NEXT:    [[SELECT_SROA_SEL:%.*]] = select i1 [[COND:%.*]], i32* [[A_SROA_0]], i32* [[B_SROA_0]]
; CHECK-NEXT:    [[SELECT2:%.*]] = select i1 [[COND]], i32* [[SELECT_SROA_SEL]], i32* [[A_SROA_0]]
; CHECK-NEXT:    [[LOAD:%.*]] = load i32, i32* [[SELECT2]], align 4
; CHECK-NEXT:    ret i32 [[LOAD]]
;
bb:
  %a = alloca %pair, align 4
  %b = alloca %pair, align 4
  %gep_a = getelementptr inbounds %pair, %pair* %a, i32 0, i32 1
  %gep_b = getelementptr inbounds %pair, %pair* %b, i32 0, i32 1
  store i32 1, i32* %gep_a, align 4
  store i32 2, i32* %gep_b, align 4
  %select = select i1 %cond, i32* %gep_a, i32* %gep_b
  %gep = getelementptr inbounds i32, i32* %select, i32 0
  %select2 = select i1 %cond, i32* %gep, i32* %gep_a
  %load = load i32, i32* %select2, align 4
  ret i32 %load
}

define i32 @test_sroa_gep_select_gep_nonconst_idx(i1 %cond, i32 %idx) {
; CHECK-LABEL: @test_sroa_gep_select_gep_nonconst_idx(
; CHECK-NEXT:  bb:
; CHECK-NEXT:    [[A:%.*]] = alloca [[PAIR:%.*]], align 4
; CHECK-NEXT:    [[B:%.*]] = alloca [[PAIR]], align 4
; CHECK-NEXT:    [[GEP_A:%.*]] = getelementptr inbounds [[PAIR]], %pair* [[A]], i32 0, i32 1
; CHECK-NEXT:    [[GEP_B:%.*]] = getelementptr inbounds [[PAIR]], %pair* [[B]], i32 0, i32 1
; CHECK-NEXT:    store i32 1, i32* [[GEP_A]], align 4
; CHECK-NEXT:    store i32 2, i32* [[GEP_B]], align 4
; CHECK-NEXT:    [[SELECT:%.*]] = select i1 [[COND:%.*]], %pair* [[A]], %pair* [[B]]
; CHECK-NEXT:    [[GEP:%.*]] = getelementptr inbounds [[PAIR]], %pair* [[SELECT]], i32 [[IDX:%.*]], i32 1
; CHECK-NEXT:    [[LOAD:%.*]] = load i32, i32* [[GEP]], align 4
; CHECK-NEXT:    ret i32 [[LOAD]]
;
bb:
  %a = alloca %pair, align 4
  %b = alloca %pair, align 4
  %gep_a = getelementptr inbounds %pair, %pair* %a, i32 0, i32 1
  %gep_b = getelementptr inbounds %pair, %pair* %b, i32 0, i32 1
  store i32 1, i32* %gep_a, align 4
  store i32 2, i32* %gep_b, align 4
  %select = select i1 %cond, %pair* %a, %pair* %b
  %gep = getelementptr inbounds %pair, %pair* %select, i32 %idx, i32 1
  %load = load i32, i32* %gep, align 4
  ret i32 %load
}
