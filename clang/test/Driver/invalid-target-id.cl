// REQUIRES: clang-driver
// REQUIRES: x86-registered-target
// REQUIRES: amdgpu-registered-target

// RUN: not %clang -target amdgcn-amd-amdhsa \
// RUN:   -mcpu=gfx908xnack -nostdlib \
// RUN:   %s 2>&1 | FileCheck -check-prefix=NOPLUS %s

// NOPLUS: error: unknown target CPU 'gfx908xnack'

// RUN: not %clang -target amdgcn-amd-amdpal \
// RUN:   -mcpu=gfx908:sramecc+:xnack+ -nostdlib \
// RUN:   %s 2>&1 | FileCheck -check-prefix=ORDER %s

// ORDER: error: Invalid target id: gfx908:sramecc+:xnack+

// RUN: not %clang -target amdgcn--mesa3d \
// RUN:   -mcpu=gfx908:unknown+ -nostdlib \
// RUN:   %s 2>&1 | FileCheck -check-prefix=UNK %s

// UNK: error: Invalid target id: gfx908:unknown+

// RUN: not %clang -target amdgcn-amd-amdhsa \
// RUN:   -mcpu=gfx908:sramecc+:unknown+ -nostdlib \
// RUN:   %s 2>&1 | FileCheck -check-prefix=MIXED %s

// MIXED: error: Invalid target id: gfx908:sramecc+:unknown+

// RUN: not %clang -target amdgcn-amd-amdhsa \
// RUN:   -mcpu=gfx900:xnack+ -nostdlib \
// RUN:   %s 2>&1 | FileCheck -check-prefix=UNSUP %s

// UNSUP: error: Invalid target id: gfx900:xnack+

// RUN: not %clang -target amdgcn-amd-amdhsa \
// RUN:   -mcpu=gfx900:xnack -nostdlib \
// RUN:   %s 2>&1 | FileCheck -check-prefix=NOSIGN %s

// NOSIGN: error: Invalid target id: gfx900:xnack

// RUN: not %clang -target amdgcn-amd-amdhsa \
// RUN:   -mcpu=gfx900+xnack -nostdlib \
// RUN:   %s 2>&1 | FileCheck -check-prefix=NOCOLON %s

// NOCOLON: error: unknown target CPU 'gfx900+xnack'
