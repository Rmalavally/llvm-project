declare i8 addrspace(2)* @llvm.amdgcn.dispatch.ptr() #0

define i32 @get_global_size(i32 %dim) #1 {
  %dispatch_ptr = call noalias nonnull dereferenceable(64) i8 addrspace(2)* @llvm.amdgcn.dispatch.ptr()
  switch i32 %dim, label %default [
    i32 0, label %x
    i32 1, label %y
    i32 2, label %z
  ]

x:
  %ptr_x = getelementptr inbounds i8, i8 addrspace(2)* %dispatch_ptr, i32 12
  %ptr_x32 = bitcast i8 addrspace(2)* %ptr_x to i32 addrspace(2)*
  %x32 = load i32, i32 addrspace(2)* %ptr_x32, align 4, !invariant.load !0
  ret i32 %x32

y:
  %ptr_y = getelementptr inbounds i8, i8 addrspace(2)* %dispatch_ptr, i32 16
  %ptr_y32 = bitcast i8 addrspace(2)* %ptr_y to i32 addrspace(2)*
  %y32 = load i32, i32 addrspace(2)* %ptr_y32, align 4, !invariant.load !0
  ret i32 %y32

z:
  %ptr_z = getelementptr inbounds i8, i8 addrspace(2)* %dispatch_ptr, i32 20
  %ptr_z32 = bitcast i8 addrspace(2)* %ptr_z to i32 addrspace(2)*
  %z32 = load i32, i32 addrspace(2)* %ptr_z32, align 4, !invariant.load !0
  ret i32 %z32

default:
  ret i32 1
}

attributes #0 = { nounwind readnone }
attributes #1 = { alwaysinline norecurse nounwind readonly }

!0 = !{}
