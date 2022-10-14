#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"


#define min(a, b) (((a) < (b)) ? (a) : (b))
#define max(a, b) (((a) > (b)) ? (a) : (b))
struct Queue mlfq_q[NMLFQ];

struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void
procinit(void)
{
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for(p = proc; p < &proc[NPROC]; p++) {
      initlock(&p->lock, "proc");
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

int
allocpid()
{
  int pid;
  
  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    acquire(&p->lock);
    if(p->state == UNUSED) {
      goto found;
    } else {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  // Allocate a trapframe page.
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    // freeproc(p);
    release(&p->lock);
    return 0;
  }
  // Allocate a trapframe page for alarm_trapframe.
  if((p->alarm_trapframe = (struct trapframe *)kalloc()) == 0){
    release(&p->lock);
    return 0;
  }

  p->alarm_goingoff = 0;
  p->alarm_interval = 0;
  p->alarm_ticks = 0;
  p->alarm_handler = 0;

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;


  // FCFS
  p->in_time = ticks;
  p->ctime = ticks;

  // PBS
  p->sleep_ticks = 0;
  p->run_ticks = 0;
  p->priority = 0;
  p->no_sched = 0;
  p->rtime = 0;
  p->etime = 0;
  p->def_pri = 60;

  // LBS
  p->tickets = 1;

  // MLFQ
  // p->level = 0;
  // p->enter_q = ticks;
  // p->run_n = 0;
  // p->change_q = 1 << p->level;
  // p->cur_q = 0;

  // int i = 0;
  // while(i < NMLFQ){
  //   p->q[i] = 0;
  //   i++;
  // }

  return p;
}

// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  if(p->trapframe)
    kfree((void*)p->trapframe);
  p->trapframe = 0;

  if(p->alarm_trapframe)
    kfree((void*)p->alarm_trapframe);
  p->alarm_trapframe = 0;

  if(p->pagetable)
    proc_freepagetable(p->pagetable, p->sz);
  p->pagetable = 0;
  p->sz = 0;
  p->pid = 0;
  p->parent = 0;
  p->name[0] = 0;
  p->chan = 0;
  p->killed = 0;
  p->xstate = 0;
  p->state = UNUSED;
  p->alarm_interval = 0;
  p->alarm_goingoff = 0;
  p->alarm_ticks = 0;
  p->alarm_handler = 0;  
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if(pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
              (uint64)trampoline, PTE_R | PTE_X) < 0){
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
              (uint64)(p->trapframe), PTE_R | PTE_W) < 0){
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void
proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

void update_time()
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    {
      p->rtime++;
      p->run_ticks++;
      // p->q[myproc()->level]++;
      // p->change_q--;
    }
    if (p->state == SLEEPING)
    {
      p->sleep_ticks++;
    }
    release(&p->lock);
  }
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
  0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
  0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
  0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
  0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
  0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
  0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00
};

// Set up first user process.
void
userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;
  
  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;      // user program counter
  p->trapframe->sp = PGSIZE;  // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if(n > 0){
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
      return -1;
    }
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int
fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if((np = allocproc()) == 0){
    return -1;
  }

  // Copy user memory from parent to child.
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;

  // increment reference counts on open file descriptors.
  for(i = 0; i < NOFILE; i++)
    if(p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void
reparent(struct proc *p)
{
  struct proc *pp;

  for(pp = proc; pp < &proc[NPROC]; pp++){
    if(pp->parent == p){
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void
exit(int status)
{
  struct proc *p = myproc();

  if(p == initproc)
    panic("init exiting");

  // Close all open files.
  for(int fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd]){
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);
  
  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(pp = proc; pp < &proc[NPROC]; pp++){
      if(pp->parent == p){
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if(pp->state == ZOMBIE){
          // Found one.
          pid = pp->pid;
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                  sizeof(pp->xstate)) < 0) {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || killed(p)){
      release(&wait_lock);
      return -1;
    }
    
    // Wait for a child to exit.
    sleep(p, &wait_lock);  //DOC: wait-sleep
  }
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.
void scheduler(void)
{
  round_robin();
  // FCFS();
  // PBS();
  // MLFQ();
  // LBS();
}

void round_robin()
{
  struct proc *p;
  struct cpu *c = mycpu();

  c->proc = 0;
  for (;;)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();

    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        // Switch to chosen process.  It is the process's job
        // to release its lock and then reacquire it
        // before jumping back to us.
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);

        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
      }
      release(&p->lock);
    }
  }
}

void FCFS()
{
  // struct proc *p;
  // struct cpu *c = mycpu();
  // c->proc = 0;
  // struct proc *first_proc = 0;
  // int min = 0;
  // int flag = 0;
  // for (;;)
  // {
  //   intr_on();
  //   for (p = proc; p < &proc[NPROC]; p++)
  //   {
  //     acquire(&p->lock);
  //     if (p->state == RUNNABLE)
  //     {
  //       if (first_proc == 0)
  //       {
  //         release(&first_proc->lock);
  //         first_proc = p;
  //         min = p->in_time;
  //         flag = 1;
  //       }
  //       else if (p->in_time < min)
  //       {
  //         release(&first_proc->lock);
  //         first_proc = p;
  //         min = p->in_time;
  //         flag = 1;
  //       }
  //     }
  //     if (flag != 1)
  //     {
  //       release(&p->lock);
  //     }
  //   }
  //   if (first_proc != 0)
  //   {
  //     if (first_proc->state == RUNNABLE)
  //     {
  //       first_proc->state = RUNNING;
  //       c->proc = first_proc;
  //       swtch(&c->context, &first_proc->context);
  //       c->proc = 0;
  //       release(&first_proc->lock);
  //     }
  //   }
  // }

  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  struct proc *first_proc = 0;
  int flag = 0;

  for (;;)
  {
    intr_on();
    first_proc = 0;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        if (first_proc == 0)
        {
          first_proc = p;
          flag = 1;
        }
        else if (p->in_time < first_proc->in_time)
        {
          release(&first_proc->lock);
          first_proc = p;
          flag = 1;
        }
      }
      if (first_proc != p)
      {
        release(&p->lock);
      }
    }
    if (first_proc != 0)
    {
      if (first_proc->state == RUNNABLE)
      {
        first_proc->state = RUNNING;
        c->proc = first_proc;
        swtch(&c->context, &first_proc->context);
        c->proc = 0;
      }
      release(&first_proc->lock);
    }
  }
}

void PBS()
{
  // struct proc *p;
  // struct cpu *c = mycpu();
  // c->proc = 0;
  // struct proc *first_proc;
  // int flag = 0;
  // int DP;
  // int min_DP;
  // int nice;
  // for (;;)
  // {
  //   intr_on();
  //   min_DP = 101;
  //   first_proc = 0;
  //   for (p = proc; p < &proc[NPROC]; p++)
  //   {
  //     acquire(&p->lock);
  //     if (p->state == RUNNABLE)
  //     {
  //       nice = niceness(p);
  //       // if (p->priority == 1 || p->no_sched == 0)
  //       // {
  //       //   nice = 5;
  //       // }
  //       // else
  //       // {
  //       //   nice = (int)(((p->sleep_ticks) / (p->sleep_ticks + p->run_ticks)) * 10);
  //       // }

  //       DP = max(0, min(p->def_pri - nice + 5, 100));

  //       if (first_proc == 0)
  //       {
  //         // release(&first_proc->lock);
  //         first_proc = p;
  //         min_DP = DP;
  //         // flag = 1;
  //       }
  //       else if (DP < min_DP)
  //       {
  //         release(&first_proc->lock);
  //         first_proc = p;
  //         min_DP = DP;
  //         // flag = 1;
  //       }
  //       else if (DP == min_DP)
  //       {
  //         if (first_proc->no_sched >= p->no_sched)
  //         {
  //           if (first_proc->no_sched == p->no_sched)
  //           {
  //             if (first_proc->ctime < p->ctime)
  //             {
  //               release(&first_proc->lock);
  //               min_DP = DP;
  //               first_proc = p;
  //               // flag = 1;
  //             }
  //           }
  //           else
  //           {
  //             release(&p->lock);
  //             min_DP = DP;
  //             first_proc = p;
  //             // flag = 1;
  //           }
  //         }
  //       }
  //     }
  //     if (first_proc != p)
  //     {
  //       release(&p->lock);
  //     }
  //   }
  //   if (first_proc != 0)
  //   {

  //     first_proc->state = RUNNING;
  //     c->proc = first_proc;
  //     swtch(&c->context, &first_proc->context);
  //     c->proc = 0;
  //     first_proc->no_sched++;
  //     first_proc->sleep_ticks = 0;
  //     first_proc->run_ticks = 0;
  //     first_proc->priority = 0;
  //     release(&first_proc->lock);
  //   }
  // }

  struct proc *p;
  struct cpu *c = mycpu();
  struct proc *top_pri;
  int dp;
  int dp_min;
  int nice;
  c->proc = 0;
  while(1)
  {
    // Avoid deadlock by ensuring that devices can interrupt.
    intr_on();
    dp_min = 101;
    top_pri = 0;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        nice = niceness(p);
        dp = max(0, min(p->def_pri - nice + 5, 100));
        if (top_pri == 0)
        {
          top_pri = p;
          dp_min = dp;
        }
        else if (dp_min > dp)
        {
          release(&top_pri->lock);
          dp_min = dp;
          top_pri = p;
        }
        else if (dp_min == dp)
        {
          if (top_pri->no_sched == p->no_sched && top_pri->ctime < p->ctime)
          {
            release(&top_pri->lock);
            dp_min = dp;
            top_pri = p;
          }
          else if (top_pri->no_sched > p->no_sched)
          {
            release(&top_pri->lock);
            dp_min = dp;
            top_pri = p;
          }
        }
      }
      if (top_pri != p)
      {
        release(&p->lock);
      }
    }
    if (top_pri)
    {
      top_pri->state = RUNNING;
      c->proc = top_pri;
      swtch(&c->context, &top_pri->context);

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
      top_pri->sleep_ticks = 0;
      top_pri->run_ticks = 0;
      top_pri->priority = 0;
      top_pri->no_sched++;
      release(&top_pri->lock);
    }
  }
}

int niceness(struct proc *p)
{
  if (p->priority == 1 || p->no_sched == 0)
  {
    return 5;
  }
  else
  {
    int val = (int)((p->sleep_ticks / (p->run_ticks + p->sleep_ticks)) * 10);
    return val;
  }
}

void LBS()
{
  // lottery based scheduling
  struct proc *p;
  struct cpu *c = mycpu();
  c->proc = 0;
  struct proc *prize = 0;
  int flag = 0;
  int total_tickets = 0;
  int ticket;
  int i;
  for (;;)
  {
    intr_on();
    total_tickets = 0;
    prize = 0;
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        total_tickets += p->tickets;
      }
      release(&p->lock);
    }
    if (total_tickets > 0)
    {
      ticket = random_max(total_tickets);
      for (p = proc; p < &proc[NPROC]; p++)
      {
        uint64 temp_sum = 0;
        acquire(&p->lock);
        if (p->state == RUNNABLE)
        {
          temp_sum += p->tickets;
          if (temp_sum >= ticket && prize == 0)
          {
            prize = p;
            flag = 1;
            // for (struct proc *x = ++prize; x < &proc[NPROC]; x++)
            // {
            //   release(&x->lock);
            // }
            continue;
          }
        }
        release(&p->lock);
      }

      if (prize != 0)
      {
        if (prize->state == RUNNABLE)
        {
          prize->state = RUNNING;
          c->proc = prize;
          swtch(&c->context, &prize->context);
          c->proc = 0;
        }
        release(&prize->lock);
      }
    }
  }
}

// void MLFQ()
// {
//     struct proc *p;
//   struct cpu *c = mycpu();
//   struct proc *pick;
//   c->proc = 0;
//   for (;;)
//   {
//     pick = 0;
//     intr_on();
//     ageing();
//     for (p = proc; p < &proc[NPROC]; p++)
//     {
//       acquire(&p->lock);
//       if (p->state == RUNNABLE && p->cur_q == 0)
//       {
//         push(&mlfq_q[p->level], p);
//         p->cur_q = 1;
//       }
//       release(&p->lock);
//     }
//     for (int level = 0; level < NMLFQ; level++)
//     {
//       while (mlfq_q[level].size)
//       {
//         struct proc *p = front(&mlfq_q[level]);
//         acquire(&p->lock);
//         pop(&mlfq_q[level]);
//         p->cur_q = 0;
//         if (p->state == RUNNABLE)
//         {
//           p->enter_q = ticks;
//           pick = p;
//           break;
//         }
//         else
//         {
//           release(&p->lock);
//         }
//       }
//       if (pick)
//       {
//         break;
//       }
//     }
//     if (pick)
//     {
//       pick->state = RUNNING;
//       pick->change_q = 1 << pick->level;
//       pick->enter_q = ticks;
//       pick->run_n++;
//       c->proc = pick;
//       swtch(&c->context, &pick->context);

//       // Process is done running for now.
//       // It should have changed its p->state before coming back.
//       c->proc = 0;
//       release(&pick->lock);
//     }
//   }
// }

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
  int intena;
  struct proc *p = myproc();

  if(!holding(&p->lock))
    panic("sched p->lock");
  if(mycpu()->noff != 1)
    panic("sched locks");
  if(p->state == RUNNING)
    panic("sched running");
  if(intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void
yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first) {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();
  
  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
        p->state = RUNNABLE;
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    acquire(&p->lock);
    if(p->pid == pid){
      p->killed = 1;
      if(p->state == SLEEPING){
        // Wake process from sleep().
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void
setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int
killed(struct proc *p)
{
  int k;
  
  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if(user_dst){
    return copyout(p->pagetable, dst, src, len);
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if(user_src){
    return copyin(p->pagetable, dst, src, len);
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
  static char *states[] = {
  [UNUSED]    "unused",
  [USED]      "used",
  [SLEEPING]  "sleep ",
  [RUNNABLE]  "runble",
  [RUNNING]   "run   ",
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
  for(p = proc; p < &proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
  }
}



// int set_priority(int new_prio, int pid)
// {
//   struct proc *p;
//   for (p = proc; p < &proc[NPROC]; p++)
//   {
//     acquire(&p->lock);
//     if (p->pid == pid)
//     {
//       int old_prio = p->def_pri;
//       p->def_pri = new_prio;
//       p->priority = 1;
//       release(&p->lock);
//       if (new_prio < old_prio)
//       {
//         yield();
//       }
//       return old_prio;
//     }
//     release(&p->lock);
//   }
//   return -1;
// }

#define RAND_MAX 32767

void pinit(void)
{
  for (int i = 0; i < NMLFQ; i++)
  {
    mlfq_q[i].size = 0;
    mlfq_q[i].head = 0;
    mlfq_q[i].tail = 0;
  }
}

int random_max(int n)
{
  // generate a random number less than n
  unsigned int num_bins = (unsigned int)n + 1;
  unsigned int num_rand = (unsigned int)RAND_MAX + 1;
  unsigned int bin_size = num_rand / num_bins;
  unsigned int defect = num_rand % num_bins;

  int x;
  do
  {
    x = ticks;
  }
  // This is carefully written not to overflow
  while (num_rand - defect <= (unsigned int)x);

  // Truncated division is intentional
  return x / bin_size;
}

void push(struct Queue *array, struct proc *p)
{
  array->array[array->tail] = p;
  array->tail = (array->tail + 1) % NPROC;

  if (array->tail == NPROC + 1)
  {
    array->tail = 0;
  }
  else if (array->tail > array->head)
  {
    array->size = array->tail - array->head;
  }

  array->size++;
}

void pop(struct Queue *array)
{
  array->head++;

  if (array->head == NPROC + 1)
  {
    array->head = 0;
  }

  array->size--;
}

struct proc *front(struct Queue *array)
{
  if (array->head == array->tail)
  {
    return 0;
  }

  return array->array[array->head];
}

int waitx(uint64 addr, uint* wtime, uint* rtime)
		
{
		
  struct proc *np;
		
  int havekids, pid;
		
  struct proc *p = myproc();
		

		
  acquire(&wait_lock);
		

		
  for(;;){
		
    // Scan through table looking for exited children.
		
    havekids = 0;
		
    for(np = proc; np < &proc[NPROC]; np++){
		
      if(np->parent == p){
		
        // make sure the child isn't still in exit() or swtch().
		
        acquire(&np->lock);
		

		
        havekids = 1;
		
        if(np->state == ZOMBIE){
		
          // Found one.
		
          pid = np->pid;
		
          *rtime = np->rtime;
		
          *wtime = np->etime - np->ctime - np->rtime;
		
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
		
                                  sizeof(np->xstate)) < 0) {
		
            release(&np->lock);
		
            release(&wait_lock);
		
            return -1;
		
          }
		
          freeproc(np);
		
          release(&np->lock);
		
          release(&wait_lock);
		
          return pid;
		
        }
		
        release(&np->lock);
		
      }
		
    }

    // No point waiting if we don't have any children.
		
    if(!havekids || p->killed){
		
      release(&wait_lock);
		
      return -1;
		
    }
		
    // Wait for a child to exit.
		
    sleep(p, &wait_lock);  //DOC: wait-sleep
		
  }
		
}
		



void qerase(struct Queue *list, struct proc *p)
{
  int pid = p->pid;
  for (int i = list->head; i < list->tail; i++)
  {
    if (list->array[i]->pid == pid)
    {
      struct proc *temp = list->array[i];
      list->array[i] = list->array[(i + 1) % (NPROC + 1)];
      list->array[(i + 1) % (NPROC + 1)] = temp;
    }
  }

  list->tail--;
  list->size--;
  if (list->tail < 0)
  {
    list->tail = NPROC;
  }
}

void ageing(void)
{
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == RUNNABLE && ticks - p->enter_q >= 128)
    {
      if (p->cur_q)
      {
        qerase(&mlfq_q[p->level], p);
        p->cur_q = 0;
      }
      if (p->level != 0)
      {
        p->level--;
      }
      p->enter_q = ticks;
    }
    release(&p->lock);
  }
}
