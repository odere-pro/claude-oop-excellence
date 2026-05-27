# Reference — Concurrency Antipattern Detection

## Table of contents

- [1. Race Condition](#1-race-condition)
- [2. Deadlock](#2-deadlock)
- [3. Busy Waiting](#3-busy-waiting)
- [4. Thread Starvation](#4-thread-starvation)

## 1. Race Condition

### Description

Shared mutable state accessed from multiple threads or async contexts without synchronization. Leads to non-deterministic behavior, data corruption, and hard-to-reproduce bugs.

### Language-specific patterns

#### JavaScript/TypeScript (async/await)

- `let` or `var` declared outside an async function, modified inside multiple `async` callbacks or `.then()` handlers
- Global or module-level mutable state accessed from `Promise.all` branches
- Missing `await` before writing to shared state (fire-and-forget mutation)
- Read-modify-write on shared variables without atomic operation (`counter++` across async boundaries)

Grep patterns:

```
let \w+\s*=         # module-level let declarations
\.then\(.*=\s*      # assignment inside .then()
Promise\.all\(      # parallel execution (check for shared state)
```

#### Python (threading)

- Global variable modified inside `threading.Thread` targets without `threading.Lock`
- `dict` or `list` mutations from multiple threads (CPython GIL does not protect compound operations)
- `asyncio.gather` branches modifying the same object

Grep patterns:

```
threading\.Thread    # thread creation
global \w+           # global variable declaration in function
```

#### Go (goroutines)

- Shared variable accessed from multiple goroutines without `sync.Mutex` or channel
- Map writes from concurrent goroutines (runtime panic)
- Closure capturing loop variable in goroutine

Grep patterns:

```
go func\(            # goroutine with closure
go \w+\(             # goroutine launch
sync\.Mutex          # mutex usage (presence = awareness)
```

#### Java (threads)

- Non-volatile field accessed from multiple threads
- `HashMap` used concurrently (should be `ConcurrentHashMap`)
- Check-then-act without synchronization (`if (map.containsKey(k)) map.get(k)`)

Grep patterns:

```
new Thread\(         # thread creation
extends Thread       # thread subclass
implements Runnable  # runnable implementation
HashMap<             # non-concurrent map
```

### False positives

- Module-level `let` that is only assigned once during initialization (effectively `const`)
- Variables scoped to a single async chain with no concurrent access
- Immutable data structures passed between async contexts
- Go channels used correctly for communication (no shared memory)

---

## 2. Deadlock

### Description

Multiple locks acquired in inconsistent order, or tasks awaiting resources held by each other in a cycle. Results in permanent hangs.

### Language-specific patterns

#### JavaScript/TypeScript

- `await` inside a lock/semaphore scope where another async path acquires the same resources in different order
- Recursive async calls that re-enter a non-reentrant lock
- `Promise` chains where resolution depends on another promise that depends on the first

Grep patterns:

```
\.acquire\(          # semaphore/lock acquisition
\.lock\(             # explicit locking
await.*acquire       # await inside lock context
```

#### Python

- `lock.acquire()` / `with lock:` in different orders across functions
- Nested `with threading.Lock()` blocks
- `asyncio.Lock` held across `await` that triggers code needing the same lock

Grep patterns:

```
lock\.acquire        # explicit lock
with.*Lock\(\)       # context manager lock
with.*lock:          # named lock context
```

#### Go

- `mu.Lock()` on multiple mutexes in different orders across goroutines
- Channel send/receive creating circular dependencies
- `sync.WaitGroup` with incorrect `Add`/`Done` counts

Grep patterns:

```
\.Lock\(\)           # mutex lock
\.RLock\(\)          # read lock
<-\w+                # channel receive
\w+\s*<-             # channel send
```

#### Java

- Nested `synchronized` blocks on different monitors in different orders
- `ReentrantLock.lock()` calls in inconsistent order
- `Future.get()` inside a thread pool task that depends on another task in the same pool

Grep patterns:

```
synchronized\s*\(    # synchronized block
\.lock\(\)           # reentrant lock
Future\.get\(        # blocking future
```

### False positives

- Single-lock patterns (no ordering issue possible)
- Locks with timeout (`tryLock` with timeout)
- Channel operations with `select` and `default` clause (non-blocking)
- Lock ordering enforced by convention and documented

---

## 3. Busy Waiting

### Description

Polling in tight loops without sleep or event-based notification. Wastes CPU cycles, increases power consumption, and delays other threads.

### Language-specific patterns

#### JavaScript/TypeScript

- `while (condition)` without `await`, `setTimeout`, or `yield` inside the body
- `setInterval` polling without `clearInterval` cleanup
- Recursive `setTimeout` without increasing backoff

Grep patterns:

```
while\s*\(.*\)\s*\{  # while loops (inspect body for await/sleep)
setInterval\(        # polling intervals
```

Thresholds:

- `setInterval` with period < 100ms without justification: `warning`
- `while` loop with no async/sleep in body: `critical`

#### Python

- `while True:` with `time.sleep(0)` or no sleep
- Polling loop without `threading.Event.wait()` or `asyncio.Event.wait()`

Grep patterns:

```
while True:          # infinite loops
time\.sleep\(0\)     # zero-duration sleep
```

#### Go

- `for { }` without `time.Sleep`, channel receive, or `select`
- `runtime.Gosched()` used as a substitute for proper synchronization

Grep patterns:

```
for \{                # infinite for loop
runtime\.Gosched     # yield without sleep
```

#### Java

- `while (flag)` without `Thread.sleep`, `wait()`, or `LockSupport.park()`
- Spin loops on `volatile` variables

Grep patterns:

```
while\s*\(.*\)\s*\{  # while loops
Thread\.sleep\(0\)   # zero-duration sleep
volatile             # volatile fields (check for spin loops)
```

### False positives

- Event loops with proper blocking (e.g., `epoll`, `kqueue`)
- Game loops or render loops with frame-rate limiting
- Spin locks in low-level performance-critical code with documented justification
- Loops with `await` or `yield` in the body

---

## 4. Thread Starvation

### Description

Thread pool exhaustion caused by long-running tasks blocking shared pools, or unbounded task queues growing without limit. Results in degraded throughput and eventual system unresponsiveness.

### Language-specific patterns

#### JavaScript/TypeScript

- `await` of CPU-intensive or I/O-blocking operations inside the main event loop without offloading to a worker
- Unbounded `Promise.all` over large arrays without concurrency limiting
- No pool size configuration for worker thread pools

Grep patterns:

```
Promise\.all\(       # unbounded parallel execution
new Worker\(         # worker creation (check for pool limits)
```

Thresholds:

- `Promise.all` over arrays > 100 items without chunking: `warning`
- Worker pool without max size: `info`

#### Python

- `ThreadPoolExecutor` or `ProcessPoolExecutor` without `max_workers`
- Blocking I/O (`requests.get`, `open().read()`) inside `asyncio` coroutine without `run_in_executor`
- `concurrent.futures.as_completed` with unbounded submissions

Grep patterns:

```
ThreadPoolExecutor   # thread pool (check for max_workers)
ProcessPoolExecutor  # process pool
requests\.get        # blocking HTTP in async context
```

#### Go

- Unbounded goroutine creation without semaphore or worker pool pattern
- `go func()` inside a loop without concurrency limit
- No `context.WithTimeout` on long operations in goroutine handlers

Grep patterns:

```
go func\(            # goroutine in loop (check for bounds)
make\(chan           # channel creation (check for buffer size)
```

#### Java

- `Executors.newCachedThreadPool()` under high load (unbounded thread creation)
- `Executors.newFixedThreadPool` with blocking operations consuming all threads
- `CompletableFuture.supplyAsync` without custom executor (uses `ForkJoinPool.commonPool`)

Grep patterns:

```
newCachedThreadPool  # unbounded pool
newFixedThreadPool   # fixed pool (check for blocking)
supplyAsync          # default pool usage
ForkJoinPool         # common pool
```

### False positives

- Worker pools with documented sizing based on workload analysis
- Bounded queues with rejection policies
- Rate-limited task submission
- Goroutines with proper semaphore patterns (`chan struct{}` as semaphore)
