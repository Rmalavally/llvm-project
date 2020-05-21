; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx900 -filetype=asm -o - %s | FileCheck --check-prefixes=CHECK,WAVE64 %s
; RUN: llc -mtriple=amdgcn-amd-amdhsa -mcpu=gfx1010 -mattr=+wavefrontsize32,-wavefrontsize64 -filetype=asm -o - %s | FileCheck --check-prefixes=CHECK,WAVE32 %s

; CHECK-LABEL: kern1:
; CHECK: .cfi_startproc

; CHECK-NOT: .cfi_{{.*}}

; CHECK: %bb.0:
; DW_CFA_def_cfa_expression [0x0f]
;   BLOCK_LENGTH ULEB128(3)=[0x03]
;     DW_OP_lit0 [0x30]
;     DW_OP_lit6 [0x36]
;     DW_OP_LLVM_form_aspace_address [0xe1]
; CHECK-NEXT: .cfi_escape 0x0f, 0x03, 0x30, 0x36, 0xe1
; PC_64 = 16
; CHECK-NEXT: .cfi_undefined 16

; CHECK-NOT: .cfi_{{.*}}

; CHECK: .cfi_endproc
define protected amdgpu_kernel void @kern1() #0 {
entry:
  ret void
}

; CHECK-LABEL: func_no_clobber:
; CHECK: .cfi_startproc

; CHECK-NOT: .cfi_{{.*}}

; CHECK: %bb.0:
; SGPR32 = 64
; CHECK-NEXT: .cfi_llvm_def_aspace_cfa 64, 0, 6
; DW_CFA_expression [0x10]
;   PC_64 ULEB128(17)=[0x10]
;   BLOCK_LENGTH ULEB128(8)=[0x08]
;     DW_OP_regx [0x90]
;       SGPR30 ULEB128(62)=[0x3e]
;     DW_OP_piece [0x93]
;       PIECE_SIZE [0x04]
;     DW_OP_regx [0x90]
;       SGPR31 ULEB128(63)=[0x3f]
;     DW_OP_piece [0x93]
;       PIECE_SIZE [0x04]
; CHECK-NEXT: .cfi_escape 0x10, 0x10, 0x08, 0x90, 0x3e, 0x93, 0x04, 0x90, 0x3f, 0x93, 0x04

; CHECK-NOT: .cfi_{{.*}}

; CHECK: .cfi_endproc
define hidden void @func_no_clobber() #0 {
entry:
  ret void
}

declare hidden void @ex() #0

; CHECK-LABEL: func_call_clobber:
; CHECK: .cfi_startproc

; CHECK-NOT: .cfi_{{.*}}

; CHECK: %bb.0:
; CHECK-NEXT: .cfi_llvm_def_aspace_cfa 64, 0, 6
; CHECK-NEXT: .cfi_escape 0x10, 0x10, 0x08, 0x90, 0x3e, 0x93, 0x04, 0x90, 0x3f, 0x93, 0x04

; VGPR0_wave64 = 2560
; WAVE64-NEXT: .cfi_undefined 2560
; WAVE64-NEXT: .cfi_undefined 2561
; WAVE64-NEXT: .cfi_undefined 2562
; WAVE64-NEXT: .cfi_undefined 2563
; WAVE64-NEXT: .cfi_undefined 2564
; WAVE64-NEXT: .cfi_undefined 2565
; WAVE64-NEXT: .cfi_undefined 2566
; WAVE64-NEXT: .cfi_undefined 2567
; WAVE64-NEXT: .cfi_undefined 2568
; WAVE64-NEXT: .cfi_undefined 2569
; WAVE64-NEXT: .cfi_undefined 2570
; WAVE64-NEXT: .cfi_undefined 2571
; WAVE64-NEXT: .cfi_undefined 2572
; WAVE64-NEXT: .cfi_undefined 2573
; WAVE64-NEXT: .cfi_undefined 2574
; WAVE64-NEXT: .cfi_undefined 2575
; WAVE64-NEXT: .cfi_undefined 2576
; WAVE64-NEXT: .cfi_undefined 2577
; WAVE64-NEXT: .cfi_undefined 2578
; WAVE64-NEXT: .cfi_undefined 2579
; WAVE64-NEXT: .cfi_undefined 2580
; WAVE64-NEXT: .cfi_undefined 2581
; WAVE64-NEXT: .cfi_undefined 2582
; WAVE64-NEXT: .cfi_undefined 2583
; WAVE64-NEXT: .cfi_undefined 2584
; WAVE64-NEXT: .cfi_undefined 2585
; WAVE64-NEXT: .cfi_undefined 2586
; WAVE64-NEXT: .cfi_undefined 2587
; WAVE64-NEXT: .cfi_undefined 2588
; WAVE64-NEXT: .cfi_undefined 2589
; WAVE64-NEXT: .cfi_undefined 2590
; WAVE64-NEXT: .cfi_undefined 2591
; WAVE64-NEXT: .cfi_undefined 2592
; WAVE64-NEXT: .cfi_undefined 2593
; WAVE64-NEXT: .cfi_undefined 2594
; WAVE64-NEXT: .cfi_undefined 2595
; WAVE64-NEXT: .cfi_undefined 2596
; WAVE64-NEXT: .cfi_undefined 2597
; WAVE64-NEXT: .cfi_undefined 2598
; WAVE64-NEXT: .cfi_undefined 2599

; VPGR48_wave64 = 2608
; WAVE64-NEXT: .cfi_undefined 2608
; WAVE64-NEXT: .cfi_undefined 2609
; WAVE64-NEXT: .cfi_undefined 2610
; WAVE64-NEXT: .cfi_undefined 2611
; WAVE64-NEXT: .cfi_undefined 2612
; WAVE64-NEXT: .cfi_undefined 2613
; WAVE64-NEXT: .cfi_undefined 2614
; WAVE64-NEXT: .cfi_undefined 2615

; WAVE64-NEXT: .cfi_undefined 2624
; WAVE64-NEXT: .cfi_undefined 2625
; WAVE64-NEXT: .cfi_undefined 2626
; WAVE64-NEXT: .cfi_undefined 2627
; WAVE64-NEXT: .cfi_undefined 2628
; WAVE64-NEXT: .cfi_undefined 2629
; WAVE64-NEXT: .cfi_undefined 2630
; WAVE64-NEXT: .cfi_undefined 2631

; WAVE64-NEXT: .cfi_undefined 2640
; WAVE64-NEXT: .cfi_undefined 2641
; WAVE64-NEXT: .cfi_undefined 2642
; WAVE64-NEXT: .cfi_undefined 2643
; WAVE64-NEXT: .cfi_undefined 2644
; WAVE64-NEXT: .cfi_undefined 2645
; WAVE64-NEXT: .cfi_undefined 2646
; WAVE64-NEXT: .cfi_undefined 2647

; WAVE64-NEXT: .cfi_undefined 2656
; WAVE64-NEXT: .cfi_undefined 2657
; WAVE64-NEXT: .cfi_undefined 2658
; WAVE64-NEXT: .cfi_undefined 2659
; WAVE64-NEXT: .cfi_undefined 2660
; WAVE64-NEXT: .cfi_undefined 2661
; WAVE64-NEXT: .cfi_undefined 2662
; WAVE64-NEXT: .cfi_undefined 2663

; WAVE64-NEXT: .cfi_undefined 2672
; WAVE64-NEXT: .cfi_undefined 2673
; WAVE64-NEXT: .cfi_undefined 2674
; WAVE64-NEXT: .cfi_undefined 2675
; WAVE64-NEXT: .cfi_undefined 2676
; WAVE64-NEXT: .cfi_undefined 2677
; WAVE64-NEXT: .cfi_undefined 2678
; WAVE64-NEXT: .cfi_undefined 2679

; WAVE64-NEXT: .cfi_undefined 2688
; WAVE64-NEXT: .cfi_undefined 2689
; WAVE64-NEXT: .cfi_undefined 2690
; WAVE64-NEXT: .cfi_undefined 2691
; WAVE64-NEXT: .cfi_undefined 2692
; WAVE64-NEXT: .cfi_undefined 2693
; WAVE64-NEXT: .cfi_undefined 2694
; WAVE64-NEXT: .cfi_undefined 2695

; WAVE64-NEXT: .cfi_undefined 2704
; WAVE64-NEXT: .cfi_undefined 2705
; WAVE64-NEXT: .cfi_undefined 2706
; WAVE64-NEXT: .cfi_undefined 2707
; WAVE64-NEXT: .cfi_undefined 2708
; WAVE64-NEXT: .cfi_undefined 2709
; WAVE64-NEXT: .cfi_undefined 2710
; WAVE64-NEXT: .cfi_undefined 2711

; WAVE64-NEXT: .cfi_undefined 2720
; WAVE64-NEXT: .cfi_undefined 2721
; WAVE64-NEXT: .cfi_undefined 2722
; WAVE64-NEXT: .cfi_undefined 2723
; WAVE64-NEXT: .cfi_undefined 2724
; WAVE64-NEXT: .cfi_undefined 2725
; WAVE64-NEXT: .cfi_undefined 2726
; WAVE64-NEXT: .cfi_undefined 2727

; WAVE64-NEXT: .cfi_undefined 2736
; WAVE64-NEXT: .cfi_undefined 2737
; WAVE64-NEXT: .cfi_undefined 2738
; WAVE64-NEXT: .cfi_undefined 2739
; WAVE64-NEXT: .cfi_undefined 2740
; WAVE64-NEXT: .cfi_undefined 2741
; WAVE64-NEXT: .cfi_undefined 2742
; WAVE64-NEXT: .cfi_undefined 2743

; WAVE64-NEXT: .cfi_undefined 2752
; WAVE64-NEXT: .cfi_undefined 2753
; WAVE64-NEXT: .cfi_undefined 2754
; WAVE64-NEXT: .cfi_undefined 2755
; WAVE64-NEXT: .cfi_undefined 2756
; WAVE64-NEXT: .cfi_undefined 2757
; WAVE64-NEXT: .cfi_undefined 2758
; WAVE64-NEXT: .cfi_undefined 2759

; WAVE64-NEXT: .cfi_undefined 2768
; WAVE64-NEXT: .cfi_undefined 2769
; WAVE64-NEXT: .cfi_undefined 2770
; WAVE64-NEXT: .cfi_undefined 2771
; WAVE64-NEXT: .cfi_undefined 2772
; WAVE64-NEXT: .cfi_undefined 2773
; WAVE64-NEXT: .cfi_undefined 2774
; WAVE64-NEXT: .cfi_undefined 2775

; WAVE64-NEXT: .cfi_undefined 2784
; WAVE64-NEXT: .cfi_undefined 2785
; WAVE64-NEXT: .cfi_undefined 2786
; WAVE64-NEXT: .cfi_undefined 2787
; WAVE64-NEXT: .cfi_undefined 2788
; WAVE64-NEXT: .cfi_undefined 2789
; WAVE64-NEXT: .cfi_undefined 2790
; WAVE64-NEXT: .cfi_undefined 2791

; WAVE64-NEXT: .cfi_undefined 2800
; WAVE64-NEXT: .cfi_undefined 2801
; WAVE64-NEXT: .cfi_undefined 2802
; WAVE64-NEXT: .cfi_undefined 2803
; WAVE64-NEXT: .cfi_undefined 2804
; WAVE64-NEXT: .cfi_undefined 2805
; WAVE64-NEXT: .cfi_undefined 2806
; WAVE64-NEXT: .cfi_undefined 2807


; VGPR0_wave32 = 1536
; WAVE32-NEXT: .cfi_undefined 1536
; WAVE32-NEXT: .cfi_undefined 1537
; WAVE32-NEXT: .cfi_undefined 1538
; WAVE32-NEXT: .cfi_undefined 1539
; WAVE32-NEXT: .cfi_undefined 1540
; WAVE32-NEXT: .cfi_undefined 1541
; WAVE32-NEXT: .cfi_undefined 1542
; WAVE32-NEXT: .cfi_undefined 1543
; WAVE32-NEXT: .cfi_undefined 1544
; WAVE32-NEXT: .cfi_undefined 1545
; WAVE32-NEXT: .cfi_undefined 1546
; WAVE32-NEXT: .cfi_undefined 1547
; WAVE32-NEXT: .cfi_undefined 1548
; WAVE32-NEXT: .cfi_undefined 1549
; WAVE32-NEXT: .cfi_undefined 1550
; WAVE32-NEXT: .cfi_undefined 1551
; WAVE32-NEXT: .cfi_undefined 1552
; WAVE32-NEXT: .cfi_undefined 1553
; WAVE32-NEXT: .cfi_undefined 1554
; WAVE32-NEXT: .cfi_undefined 1555
; WAVE32-NEXT: .cfi_undefined 1556
; WAVE32-NEXT: .cfi_undefined 1557
; WAVE32-NEXT: .cfi_undefined 1558
; WAVE32-NEXT: .cfi_undefined 1559
; WAVE32-NEXT: .cfi_undefined 1560
; WAVE32-NEXT: .cfi_undefined 1561
; WAVE32-NEXT: .cfi_undefined 1562
; WAVE32-NEXT: .cfi_undefined 1563
; WAVE32-NEXT: .cfi_undefined 1564
; WAVE32-NEXT: .cfi_undefined 1565
; WAVE32-NEXT: .cfi_undefined 1566
; WAVE32-NEXT: .cfi_undefined 1567
; WAVE32-NEXT: .cfi_undefined 1568
; WAVE32-NEXT: .cfi_undefined 1569
; WAVE32-NEXT: .cfi_undefined 1570
; WAVE32-NEXT: .cfi_undefined 1571
; WAVE32-NEXT: .cfi_undefined 1572
; WAVE32-NEXT: .cfi_undefined 1573
; WAVE32-NEXT: .cfi_undefined 1574
; WAVE32-NEXT: .cfi_undefined 1575

; VPGR48_wave64 = 1584
; WAVE32-NEXT: .cfi_undefined 1584
; WAVE32-NEXT: .cfi_undefined 1585
; WAVE32-NEXT: .cfi_undefined 1586
; WAVE32-NEXT: .cfi_undefined 1587
; WAVE32-NEXT: .cfi_undefined 1588
; WAVE32-NEXT: .cfi_undefined 1589
; WAVE32-NEXT: .cfi_undefined 1590
; WAVE32-NEXT: .cfi_undefined 1591

; WAVE32-NEXT: .cfi_undefined 1600
; WAVE32-NEXT: .cfi_undefined 1601
; WAVE32-NEXT: .cfi_undefined 1602
; WAVE32-NEXT: .cfi_undefined 1603
; WAVE32-NEXT: .cfi_undefined 1604
; WAVE32-NEXT: .cfi_undefined 1605
; WAVE32-NEXT: .cfi_undefined 1606
; WAVE32-NEXT: .cfi_undefined 1607

; WAVE32-NEXT: .cfi_undefined 1616
; WAVE32-NEXT: .cfi_undefined 1617
; WAVE32-NEXT: .cfi_undefined 1618
; WAVE32-NEXT: .cfi_undefined 1619
; WAVE32-NEXT: .cfi_undefined 1620
; WAVE32-NEXT: .cfi_undefined 1621
; WAVE32-NEXT: .cfi_undefined 1622
; WAVE32-NEXT: .cfi_undefined 1623

; WAVE32-NEXT: .cfi_undefined 1632
; WAVE32-NEXT: .cfi_undefined 1633
; WAVE32-NEXT: .cfi_undefined 1634
; WAVE32-NEXT: .cfi_undefined 1635
; WAVE32-NEXT: .cfi_undefined 1636
; WAVE32-NEXT: .cfi_undefined 1637
; WAVE32-NEXT: .cfi_undefined 1638
; WAVE32-NEXT: .cfi_undefined 1639

; WAVE32-NEXT: .cfi_undefined 1648
; WAVE32-NEXT: .cfi_undefined 1649
; WAVE32-NEXT: .cfi_undefined 1650
; WAVE32-NEXT: .cfi_undefined 1651
; WAVE32-NEXT: .cfi_undefined 1652
; WAVE32-NEXT: .cfi_undefined 1653
; WAVE32-NEXT: .cfi_undefined 1654
; WAVE32-NEXT: .cfi_undefined 1655

; WAVE32-NEXT: .cfi_undefined 1664
; WAVE32-NEXT: .cfi_undefined 1665
; WAVE32-NEXT: .cfi_undefined 1666
; WAVE32-NEXT: .cfi_undefined 1667
; WAVE32-NEXT: .cfi_undefined 1668
; WAVE32-NEXT: .cfi_undefined 1669
; WAVE32-NEXT: .cfi_undefined 1670
; WAVE32-NEXT: .cfi_undefined 1671

; WAVE32-NEXT: .cfi_undefined 1680
; WAVE32-NEXT: .cfi_undefined 1681
; WAVE32-NEXT: .cfi_undefined 1682
; WAVE32-NEXT: .cfi_undefined 1683
; WAVE32-NEXT: .cfi_undefined 1684
; WAVE32-NEXT: .cfi_undefined 1685
; WAVE32-NEXT: .cfi_undefined 1686
; WAVE32-NEXT: .cfi_undefined 1687

; WAVE32-NEXT: .cfi_undefined 1696
; WAVE32-NEXT: .cfi_undefined 1697
; WAVE32-NEXT: .cfi_undefined 1698
; WAVE32-NEXT: .cfi_undefined 1699
; WAVE32-NEXT: .cfi_undefined 1700
; WAVE32-NEXT: .cfi_undefined 1701
; WAVE32-NEXT: .cfi_undefined 1702
; WAVE32-NEXT: .cfi_undefined 1703

; WAVE32-NEXT: .cfi_undefined 1712
; WAVE32-NEXT: .cfi_undefined 1713
; WAVE32-NEXT: .cfi_undefined 1714
; WAVE32-NEXT: .cfi_undefined 1715
; WAVE32-NEXT: .cfi_undefined 1716
; WAVE32-NEXT: .cfi_undefined 1717
; WAVE32-NEXT: .cfi_undefined 1718
; WAVE32-NEXT: .cfi_undefined 1719

; WAVE32-NEXT: .cfi_undefined 1728
; WAVE32-NEXT: .cfi_undefined 1729
; WAVE32-NEXT: .cfi_undefined 1730
; WAVE32-NEXT: .cfi_undefined 1731
; WAVE32-NEXT: .cfi_undefined 1732
; WAVE32-NEXT: .cfi_undefined 1733
; WAVE32-NEXT: .cfi_undefined 1734
; WAVE32-NEXT: .cfi_undefined 1735

; WAVE32-NEXT: .cfi_undefined 1744
; WAVE32-NEXT: .cfi_undefined 1745
; WAVE32-NEXT: .cfi_undefined 1746
; WAVE32-NEXT: .cfi_undefined 1747
; WAVE32-NEXT: .cfi_undefined 1748
; WAVE32-NEXT: .cfi_undefined 1749
; WAVE32-NEXT: .cfi_undefined 1750
; WAVE32-NEXT: .cfi_undefined 1751

; WAVE32-NEXT: .cfi_undefined 1760
; WAVE32-NEXT: .cfi_undefined 1761
; WAVE32-NEXT: .cfi_undefined 1762
; WAVE32-NEXT: .cfi_undefined 1763
; WAVE32-NEXT: .cfi_undefined 1764
; WAVE32-NEXT: .cfi_undefined 1765
; WAVE32-NEXT: .cfi_undefined 1766
; WAVE32-NEXT: .cfi_undefined 1767

; WAVE32-NEXT: .cfi_undefined 1776
; WAVE32-NEXT: .cfi_undefined 1777
; WAVE32-NEXT: .cfi_undefined 1778
; WAVE32-NEXT: .cfi_undefined 1779
; WAVE32-NEXT: .cfi_undefined 1780
; WAVE32-NEXT: .cfi_undefined 1781
; WAVE32-NEXT: .cfi_undefined 1782
; WAVE32-NEXT: .cfi_undefined 1783


; SGPR0 = 32
; CHECK-NEXT: .cfi_undefined 32
; CHECK-NEXT: .cfi_undefined 33
; CHECK-NEXT: .cfi_undefined 34
; CHECK-NEXT: .cfi_undefined 35
; CHECK-NEXT: .cfi_undefined 36
; CHECK-NEXT: .cfi_undefined 37
; CHECK-NEXT: .cfi_undefined 38
; CHECK-NEXT: .cfi_undefined 39
; CHECK-NEXT: .cfi_undefined 40
; CHECK-NEXT: .cfi_undefined 41
; CHECK-NEXT: .cfi_undefined 42
; CHECK-NEXT: .cfi_undefined 43
; CHECK-NEXT: .cfi_undefined 44
; CHECK-NEXT: .cfi_undefined 45
; CHECK-NEXT: .cfi_undefined 46
; CHECK-NEXT: .cfi_undefined 47
; CHECK-NEXT: .cfi_undefined 48
; CHECK-NEXT: .cfi_undefined 49
; CHECK-NEXT: .cfi_undefined 50
; CHECK-NEXT: .cfi_undefined 51
; CHECK-NEXT: .cfi_undefined 52
; CHECK-NEXT: .cfi_undefined 53
; CHECK-NEXT: .cfi_undefined 54
; CHECK-NEXT: .cfi_undefined 55
; CHECK-NEXT: .cfi_undefined 56
; CHECK-NEXT: .cfi_undefined 57
; CHECK-NEXT: .cfi_undefined 58
; CHECK-NEXT: .cfi_undefined 59
; CHECK-NEXT: .cfi_undefined 60
; CHECK-NEXT: .cfi_undefined 61
; CHECK-NEXT: .cfi_undefined 62
; CHECK-NEXT: .cfi_undefined 63

; CHECK-NOT: .cfi_{{.*}}

; WAVE64: s_or_saveexec_b64 s[4:5], -1
; WAVE32: s_or_saveexec_b32 s4, -1
; CHECK-NEXT: buffer_store_dword v40, off, s[0:3], s32 ; 4-byte Folded Spill
; VGPR40_wave64 = 2600
; WAVE64-NEXT: .cfi_offset 2600, 0
; VGPR40_wave32 = 1576
; WAVE32-NEXT: .cfi_offset 1576, 0
; CHECK-NOT: .cfi_{{.*}}
; WAVE64: s_mov_b64 exec, s[4:5]
; WAVE32: s_mov_b32 exec_lo, s4

; CHECK-NOT: .cfi_{{.*}}

; CHECK: v_writelane_b32 v40, s33, 2

; DW_CFA_expression [0x10] SGPR33 ULEB128(65)=[0x41]
;   BLOCK_LENGTH ULEB128(5)=[0x05]
;     DW_OP_regx [0x90]
;       VGPR40_wave64 ULEB128(2600)=[0xa8, 0x14]
;     DW_OP_LLVM_offset_uconst [0xe4]
;       OFFSET ULEB128(0x08) [0x08]
; WAVE64-NEXT: .cfi_escape 0x10, 0x41, 0x05, 0x90, 0xa8, 0x14, 0xe4, 0x08

; DW_CFA_expression [0x10] SGPR33 ULEB128(65)=[0x41]
;   BLOCK_LENGTH ULEB128(5)=[0x05]
;     DW_OP_regx [0x90]
;       VGPR40_wave32 ULEB128(1576)=[0xa8, 0x0c]
;     DW_OP_LLVM_offset_uconst [0xe4]
;       OFFSET ULEB128(0x08) [0x08]
; WAVE32-NEXT: .cfi_escape 0x10, 0x41, 0x05, 0x90, 0xa8, 0x0c, 0xe4, 0x08

; CHECK-NOT: .cfi_{{.*}}

; CHECK: s_mov_b32 s33, s32
; SGPR33 = 65
; CHECK-NEXT: .cfi_def_cfa_register 65

; CHECK-NOT: .cfi_{{.*}}

; CHECK: s_sub_u32 s32, s32,
; CHECK-NEXT: v_readlane_b32 s33, v40, 2
; SGPR32 = 64
; CHECK-NEXT: .cfi_def_cfa_register 64

; CHECK-NOT: .cfi_{{.*}}

; CHECK: .cfi_endproc
define hidden void @func_call_clobber() #0 {
entry:
  call void @ex() #0
  ret void
}

attributes #0 = { nounwind }
attributes #1 = { nounwind "frame-pointer"="all" }

!llvm.dbg.cu = !{!0}
!llvm.module.flags = !{!2, !3}

!0 = distinct !DICompileUnit(language: DW_LANG_C99, file: !1, emissionKind: FullDebug)
!1 = !DIFile(filename: "filename", directory: "directory")
!2 = !{i32 7, !"Dwarf Version", i32 4}
!3 = !{i32 2, !"Debug Info Version", i32 3}
