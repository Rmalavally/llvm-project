//===---- omptarget.h - OpenMP GPU initialization ---------------- CUDA -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of all library macros, types,
// and functions.
//
//===----------------------------------------------------------------------===//

#ifndef OMPTARGET_H
#define OMPTARGET_H

#include "target_impl.h"
#include "common/debug.h"     // debug
#include "interface.h" // interfaces with omp, compiler, and user
#include "common/state-queue.h"
#include "common/support.h"
#include "common/ompd-specific.h"

#define OMPTARGET_NVPTX_VERSION 1.1

// used by the library for the interface with the app
#define DISPATCH_FINISHED 0
#define DISPATCH_NOTFINISHED 1

// used by dynamic scheduling
#define FINISHED 0
#define NOT_FINISHED 1
#define LAST_CHUNK 2

#define BARRIER_COUNTER 0
#define ORDERED_COUNTER 1

// arguments needed for L0 parallelism only.
class omptarget_nvptx_SharedArgs {
public:
  // All these methods must be called by the master thread only.
  INLINE void Init() {
    args  = buffer;
    nArgs = MAX_SHARED_ARGS;
  }
  INLINE void DeInit() {
    // Free any memory allocated for outlined parallel function with a large
    // number of arguments.
    if (nArgs > MAX_SHARED_ARGS) {
      SafeFree(args, "new extended args");
      Init();
    }
  }
  INLINE void EnsureSize(size_t size) {
    if (size > nArgs) {
      if (nArgs > MAX_SHARED_ARGS) {
        SafeFree(args, "new extended args");
      }
      args = (void **)SafeMalloc(size * sizeof(void *), "new extended args");
      nArgs = size;
    }
  }
  // Called by all threads.
  INLINE void **GetArgs() const { return args; };
private:
  // buffer of pre-allocated arguments.
  void *buffer[MAX_SHARED_ARGS];
  // pointer to arguments buffer.
  // starts off as a pointer to 'buffer' but can be dynamically allocated.
  void **args;
  // starts off as MAX_SHARED_ARGS but can increase in size.
  uint32_t nArgs;
};

extern DEVICE SHARED omptarget_nvptx_SharedArgs
    omptarget_nvptx_globalArgs;

// Data structure to keep in shared memory that traces the current slot, stack,
// and frame pointer as well as the active threads that didn't exit the current
// environment.
struct DataSharingStateTy {
  __kmpc_data_sharing_slot *SlotPtr[DS_Max_Warp_Number];
  void *StackPtr[DS_Max_Warp_Number];
  void * volatile FramePtr[DS_Max_Warp_Number];
  __kmpc_impl_lanemask_t ActiveThreads[DS_Max_Warp_Number];
};
// Additional worker slot type which is initialized with the default worker slot
// size of 4*32 bytes.
struct __kmpc_data_sharing_worker_slot_static {
  __kmpc_data_sharing_slot *Next;
  __kmpc_data_sharing_slot *Prev;
  void *PrevSlotStackPtr;
  void *DataEnd;
  char Data[DS_Worker_Warp_Slot_Size];
};
// Additional master slot type which is initialized with the default master slot
// size of 4 bytes.
struct __kmpc_data_sharing_master_slot_static {
  __kmpc_data_sharing_slot *Next;
  __kmpc_data_sharing_slot *Prev;
  void *PrevSlotStackPtr;
  void *DataEnd;
  char Data[DS_Slot_Size];
};
extern DEVICE SHARED DataSharingStateTy DataSharingState;

////////////////////////////////////////////////////////////////////////////////
// task ICV and (implicit & explicit) task state

class omptarget_nvptx_TaskDescr {
#if OMPD_SUPPORT
  friend void __device__ ompd_init( void );
  friend INLINE void ompd_init_thread(
      omptarget_nvptx_TaskDescr *currTaskDescr, void *task_func,
      uint8_t implicit);
  friend __device__ void  ompd_set_device_specific_thread_state(
      omptarget_nvptx_TaskDescr *taskDescr, omp_state_t state);
#endif /* OMPD_SUPPORT */
public:
  // methods for flags
  INLINE omp_sched_t GetRuntimeSched() const;
  INLINE void SetRuntimeSched(omp_sched_t sched);
  INLINE int InParallelRegion() const { return items.flags & TaskDescr_InPar; }
  INLINE int InL2OrHigherParallelRegion() const {
    return items.flags & TaskDescr_InParL2P;
  }
  INLINE int IsParallelConstruct() const {
    return items.flags & TaskDescr_IsParConstr;
  }
  INLINE int IsTaskConstruct() const { return !IsParallelConstruct(); }
  // methods for other fields
  INLINE uint16_t &ThreadId() { return items.threadId; }
  INLINE uint8_t &ParLev() { return items.parLev; }
  INLINE uint64_t &RuntimeChunkSize() { return items.runtimeChunkSize; }
  INLINE omptarget_nvptx_TaskDescr *GetPrevTaskDescr() const { return prev; }
  INLINE void SetPrevTaskDescr(omptarget_nvptx_TaskDescr *taskDescr) {
    prev = taskDescr;
  }
  // init & copy
  INLINE void InitLevelZeroTaskDescr();
  INLINE void InitLevelOneTaskDescr(omptarget_nvptx_TaskDescr *parentTaskDescr);
  INLINE void Copy(omptarget_nvptx_TaskDescr *sourceTaskDescr);
  INLINE void CopyData(omptarget_nvptx_TaskDescr *sourceTaskDescr);
  INLINE void CopyParent(omptarget_nvptx_TaskDescr *parentTaskDescr);
  INLINE void CopyForExplicitTask(omptarget_nvptx_TaskDescr *parentTaskDescr);
  INLINE void CopyToWorkDescr(omptarget_nvptx_TaskDescr *masterTaskDescr);
  INLINE void CopyFromWorkDescr(omptarget_nvptx_TaskDescr *workTaskDescr);
  INLINE void CopyConvergentParent(omptarget_nvptx_TaskDescr *parentTaskDescr,
                                   uint16_t tid, uint16_t tnum);
#ifdef OMPD_SUPPORT
  INLINE ompd_nvptx_thread_info_t *ompd_ThreadInfo() {
    return &ompd_thread_info;
  }
#endif
  INLINE void SaveLoopData();
  INLINE void RestoreLoopData() const;

private:
  // bits for flags: (6 used, 2 free)
  //   3 bits (SchedMask) for runtime schedule
  //   1 bit (InPar) if this thread has encountered one or more parallel region
  //   1 bit (IsParConstr) if ICV for a parallel region (false = explicit task)
  //   1 bit (InParL2+) if this thread has encountered L2 or higher parallel
  //   region
  static const uint8_t TaskDescr_SchedMask = (0x1 | 0x2 | 0x4);
  static const uint8_t TaskDescr_InPar = 0x10;
  static const uint8_t TaskDescr_IsParConstr = 0x20;
  static const uint8_t TaskDescr_InParL2P = 0x40;

  struct SavedLoopDescr_items {
    int64_t loopUpperBound;
    int64_t nextLowerBound;
    int64_t chunk;
    int64_t stride;
    kmp_sched_t schedule;
  } loopData;

  struct TaskDescr_items {
    uint8_t flags; // 6 bit used (see flag above)
    uint8_t parLev;
    uint16_t threadId;         // thread id
    uint64_t runtimeChunkSize; // runtime chunk size
  } items;
#ifdef OMPD_SUPPORT
  ompd_nvptx_thread_info_t ompd_thread_info;
#endif
  omptarget_nvptx_TaskDescr *prev;
};

// build on kmp
typedef struct omptarget_nvptx_ExplicitTaskDescr {
  omptarget_nvptx_TaskDescr
      taskDescr; // omptarget_nvptx task description (must be first)
  kmp_TaskDescr kmpTaskDescr; // kmp task description (must be last)
} omptarget_nvptx_ExplicitTaskDescr;

////////////////////////////////////////////////////////////////////////////////
// Descriptor of a parallel region (worksharing in general)

class omptarget_nvptx_WorkDescr {

public:
  // access to data
  INLINE omptarget_nvptx_TaskDescr *WorkTaskDescr() { return &masterTaskICV; }

private:
  omptarget_nvptx_TaskDescr masterTaskICV;
};

////////////////////////////////////////////////////////////////////////////////

class omptarget_nvptx_TeamDescr {
#ifdef OMPD_SUPPORT
  friend void __device__ ompd_init( void );
#endif /*OMPD_SUPPORT*/
public:
  // access to data
  INLINE omptarget_nvptx_TaskDescr *LevelZeroTaskDescr() {
    return &levelZeroTaskDescr;
  }
  INLINE omptarget_nvptx_WorkDescr &WorkDescr() {
    return workDescrForActiveParallel;
  }

  // init
  INLINE void InitTeamDescr();

  INLINE __kmpc_data_sharing_slot *RootS(int wid, bool IsMasterThread) {
    // If this is invoked by the master thread of the master warp then
    // initialize it with a smaller slot.
    if (IsMasterThread) {
      // Do not initialize this slot again if it has already been initalized.
      if (master_rootS[0].DataEnd == &master_rootS[0].Data[0] + DS_Slot_Size)
        return 0;
      // Initialize the pointer to the end of the slot given the size of the
      // data section. DataEnd is non-inclusive.
      master_rootS[0].DataEnd = &master_rootS[0].Data[0] + DS_Slot_Size;
      // We currently do not have a next slot.
      master_rootS[0].Next = 0;
      master_rootS[0].Prev = 0;
      master_rootS[0].PrevSlotStackPtr = 0;
      return (__kmpc_data_sharing_slot *)&master_rootS[0];
    }
    // Do not initialize this slot again if it has already been initalized.
    if (worker_rootS[wid].DataEnd ==
        &worker_rootS[wid].Data[0] + DS_Worker_Warp_Slot_Size)
      return 0;
    // Initialize the pointer to the end of the slot given the size of the data
    // section. DataEnd is non-inclusive.
    worker_rootS[wid].DataEnd =
        &worker_rootS[wid].Data[0] + DS_Worker_Warp_Slot_Size;
    // We currently do not have a next slot.
    worker_rootS[wid].Next = 0;
    worker_rootS[wid].Prev = 0;
    worker_rootS[wid].PrevSlotStackPtr = 0;
    return (__kmpc_data_sharing_slot *)&worker_rootS[wid];
  }

  INLINE __kmpc_data_sharing_slot *GetPreallocatedSlotAddr(int wid) {
    worker_rootS[wid].DataEnd =
        &worker_rootS[wid].Data[0] + DS_Worker_Warp_Slot_Size;
    // We currently do not have a next slot.
    worker_rootS[wid].Next = 0;
    worker_rootS[wid].Prev = 0;
    worker_rootS[wid].PrevSlotStackPtr = 0;
    return (__kmpc_data_sharing_slot *)&worker_rootS[wid];
  }

private:
  omptarget_nvptx_TaskDescr
      levelZeroTaskDescr; // icv for team master initial thread
  omptarget_nvptx_WorkDescr
      workDescrForActiveParallel; // one, ONLY for the active par

  ALIGN(16)
  __kmpc_data_sharing_worker_slot_static worker_rootS[DS_Max_Warp_Number];
  ALIGN(16) __kmpc_data_sharing_master_slot_static master_rootS[1];
};

////////////////////////////////////////////////////////////////////////////////
// thread private data (struct of arrays for better coalescing)
// tid refers here to the global thread id
// do not support multiple concurrent kernel a this time
class omptarget_nvptx_ThreadPrivateContext {
#if OMPD_SUPPORT
  friend void __device__ ompd_init( void );
#endif /* OMPD_SUPPORT */
public:
  // task
  INLINE omptarget_nvptx_TaskDescr *Level1TaskDescr(int tid) {
    return &levelOneTaskDescr[tid];
  }
  INLINE void SetTopLevelTaskDescr(int tid,
                                   omptarget_nvptx_TaskDescr *taskICV) {
    topTaskDescr[tid] = taskICV;
  }
  INLINE omptarget_nvptx_TaskDescr *GetTopLevelTaskDescr(int tid) const;
  // parallel
  INLINE uint16_t &NumThreadsForNextParallel(int tid) {
    return nextRegion.tnum[tid];
  }
  // schedule (for dispatch)
  INLINE kmp_sched_t &ScheduleType(int tid) { return schedule[tid]; }
  INLINE int64_t &Chunk(int tid) { return chunk[tid]; }
  INLINE int64_t &LoopUpperBound(int tid) { return loopUpperBound[tid]; }
  INLINE int64_t &NextLowerBound(int tid) { return nextLowerBound[tid]; }
  INLINE int64_t &Stride(int tid) { return stride[tid]; }

  INLINE omptarget_nvptx_TeamDescr &TeamContext() { return teamContext; }

  INLINE void InitThreadPrivateContext(int tid);
  INLINE uint64_t &Cnt() { return cnt; }

private:
  // team context for this team
  omptarget_nvptx_TeamDescr teamContext;
  // task ICV for implicit threads in the only parallel region
  omptarget_nvptx_TaskDescr levelOneTaskDescr[MAX_THREADS_PER_TEAM];
  // pointer where to find the current task ICV (top of the stack)
  omptarget_nvptx_TaskDescr *topTaskDescr[MAX_THREADS_PER_TEAM];
  union {
    // Only one of the two is live at the same time.
    // parallel
    uint16_t tnum[MAX_THREADS_PER_TEAM];
  } nextRegion;
  // schedule (for dispatch)
  kmp_sched_t schedule[MAX_THREADS_PER_TEAM]; // remember schedule type for #for
  int64_t chunk[MAX_THREADS_PER_TEAM];
  int64_t loopUpperBound[MAX_THREADS_PER_TEAM];
  // state for dispatch with dyn/guided OR static (never use both at a time)
  int64_t nextLowerBound[MAX_THREADS_PER_TEAM];
  int64_t stride[MAX_THREADS_PER_TEAM];
  uint64_t cnt;
#ifdef OMPD_SUPPORT
  // The implicit parallel region around the master task in generic mode
  ompd_nvptx_parallel_info_t ompd_levelZeroParallelInfo;
#endif
};

/// Memory manager for statically allocated memory.
class omptarget_nvptx_SimpleMemoryManager {
private:
  ALIGN(128) struct MemDataTy {
    volatile unsigned keys[OMP_STATE_COUNT];
  } MemData[MAX_SM];

  INLINE static uint32_t hash(unsigned key) {
    return key & (OMP_STATE_COUNT - 1);
  }

public:
  INLINE void Release();
  INLINE const void *Acquire(const void *buf, size_t size);
};

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// global data tables
////////////////////////////////////////////////////////////////////////////////

extern DEVICE omptarget_nvptx_SimpleMemoryManager
    omptarget_nvptx_simpleMemoryManager;
extern DEVICE SHARED uint32_t usedMemIdx;
extern DEVICE SHARED uint32_t usedSlotIdx;
#ifdef __AMDGCN__
extern DEVICE SHARED uint8_t
    parallelLevel[MAX_THREADS_PER_TEAM / WARPSIZE];
#else
extern DEVICE SHARED uint8_t
    parallelLevel[MAX_THREADS_PER_TEAM / WARPSIZE];
#endif
extern DEVICE SHARED uint16_t threadLimit;
extern DEVICE SHARED uint16_t threadsInTeam;
extern DEVICE SHARED uint16_t nThreads;
extern DEVICE SHARED
    omptarget_nvptx_ThreadPrivateContext *omptarget_nvptx_threadPrivateContext;

extern DEVICE SHARED uint32_t execution_param;
extern DEVICE SHARED void *ReductionScratchpadPtr;

////////////////////////////////////////////////////////////////////////////////
// work function (outlined parallel/simd functions) and arguments.
// needed for L1 parallelism only.
////////////////////////////////////////////////////////////////////////////////

typedef void *omptarget_nvptx_WorkFn;
extern volatile DEVICE SHARED omptarget_nvptx_WorkFn
    omptarget_nvptx_workFn;
#ifdef __AMDGCN__
extern DEVICE SHARED bool omptarget_workers_active;
extern DEVICE SHARED bool omptarget_master_active;
#endif

////////////////////////////////////////////////////////////////////////////////
// get private data structures
////////////////////////////////////////////////////////////////////////////////

INLINE omptarget_nvptx_TeamDescr &getMyTeamDescriptor();
INLINE omptarget_nvptx_WorkDescr &getMyWorkDescriptor();
INLINE omptarget_nvptx_TaskDescr *
getMyTopTaskDescriptor(bool isSPMDExecutionMode);
INLINE omptarget_nvptx_TaskDescr *getMyTopTaskDescriptor(int globalThreadId);

////////////////////////////////////////////////////////////////////////////////
// inlined implementation
////////////////////////////////////////////////////////////////////////////////

#include "common/omptargeti.h"

#endif
