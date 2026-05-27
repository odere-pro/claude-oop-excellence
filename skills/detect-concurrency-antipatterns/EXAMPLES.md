# Examples — Concurrency Antipattern Detection

## Table of contents

- [Example 1: Node.js API server with race conditions and busy waiting](#example-1-nodejs-api-server-with-race-conditions-and-busy-waiting)
- [Example 2: Python worker pool with thread starvation and deadlock](#example-2-python-worker-pool-with-thread-starvation-and-deadlock)
- [Example 3: Go service with goroutine leak and race condition](#example-3-go-service-with-goroutine-leak-and-race-condition)

## Example 1: Node.js API server with race conditions and busy waiting

### Input code

**`src/cache.ts`**

```typescript
let cache: Record<string, string> = {};

export async function getOrFetch(key: string): Promise<string> {
  if (cache[key]) {
    return cache[key];
  }
  const value = await fetchFromDB(key);
  cache[key] = value; // Race: multiple callers can fetch simultaneously
  return value;
}

export async function invalidateAndRefresh(key: string): Promise<void> {
  delete cache[key];
  // No await — fire-and-forget mutation while getOrFetch may be reading
  fetchFromDB(key).then((v) => {
    cache[key] = v;
  });
}
```

**`src/poller.ts`**

```typescript
let ready = false;

export function waitForReady(): void {
  while (!ready) {
    // Busy wait: no sleep, no await, no yield
  }
  console.log('Ready!');
}

export function markReady(): void {
  ready = true;
}
```

### Detection output

```
# Concurrency Antipattern Report

**Scanned:** 2 files
**Concurrency model:** async/await
**Findings:** 1 critical, 2 warnings, 0 info

## Critical
- [Busy Waiting] src/poller.ts:4 — `while (!ready)` loop with no await/sleep/yield blocks the event loop indefinitely

## Warnings
- [Race Condition] src/cache.ts:3 — Module-level `let cache` modified by concurrent async callers in `getOrFetch`; multiple simultaneous cache misses cause redundant fetches and last-write-wins
- [Race Condition] src/cache.ts:12 — `invalidateAndRefresh` uses fire-and-forget `.then()` to mutate `cache` while `getOrFetch` may be reading the same key

## Recommendations
1. **[Critical] Replace busy wait in poller.ts** — Use an EventEmitter, Promise, or `setTimeout`-based polling with backoff instead of a synchronous `while` loop
2. **[Warning] Add mutex or deduplication to cache.ts** — Use a promise cache pattern (store the pending Promise, not the resolved value) to prevent concurrent fetch races
3. **[Warning] Await the refresh in invalidateAndRefresh** — Either `await` the fetch or use a lock to prevent concurrent read/write on the same cache key
```

---

## Example 2: Python worker pool with thread starvation and deadlock

### Input code

**`worker/pool.py`**

```python
import threading
from concurrent.futures import ThreadPoolExecutor

db_lock = threading.Lock()
cache_lock = threading.Lock()

def update_user(user_id):
    with db_lock:
        user = fetch_user(user_id)
        with cache_lock:
            update_cache(user)

def refresh_cache():
    with cache_lock:
        entries = get_stale_entries()
        with db_lock:  # Deadlock: acquires locks in opposite order
            for entry in entries:
                reload_from_db(entry)

executor = ThreadPoolExecutor()  # No max_workers limit

def handle_request(request):
    executor.submit(process, request)  # Unbounded submissions
```

### Detection output

```
# Concurrency Antipattern Report

**Scanned:** 1 files
**Concurrency model:** threads
**Findings:** 1 critical, 1 warning, 0 info

## Critical
- [Deadlock] worker/pool.py:8,14 — `update_user` acquires db_lock then cache_lock; `refresh_cache` acquires cache_lock then db_lock. Inconsistent lock ordering creates deadlock potential

## Warnings
- [Thread Starvation] worker/pool.py:20 — `ThreadPoolExecutor()` created without `max_workers` parameter; unbounded thread creation under load can exhaust system resources

## Recommendations
1. **[Critical] Enforce consistent lock ordering** — Always acquire `cache_lock` before `db_lock` (or vice versa) across all functions. Alternatively, combine into a single lock if the critical sections are short
2. **[Warning] Set max_workers on ThreadPoolExecutor** — Use `ThreadPoolExecutor(max_workers=N)` with N based on workload analysis (e.g., `os.cpu_count() * 2` for I/O-bound tasks)
```

---

## Example 3: Go service with goroutine leak and race condition

### Input code

**`handler/process.go`**

```go
package handler

var results = make(map[string]string)

func ProcessBatch(items []string) {
    for _, item := range items {
        go func() {
            result := compute(item) // Bug: captures loop variable
            results[item] = result  // Race: concurrent map write
        }()
    }
}

func PollStatus(id string) string {
    for {
        if val, ok := results[id]; ok {
            return val
        }
        // Busy wait: no sleep or select
    }
}
```

### Detection output

```
# Concurrency Antipattern Report

**Scanned:** 1 files
**Concurrency model:** threads (goroutines)
**Findings:** 2 critical, 1 warning, 0 info

## Critical
- [Race Condition] handler/process.go:8 — Concurrent goroutines write to shared `results` map without sync.Mutex; causes runtime panic in Go
- [Busy Waiting] handler/process.go:14 — `for {}` loop polls `results` map with no `time.Sleep`, channel receive, or `select` statement

## Warnings
- [Race Condition] handler/process.go:7 — Goroutine closure captures loop variable `item` by reference; all goroutines may process the last item only

## Recommendations
1. **[Critical] Protect shared map with sync.Mutex or use sync.Map** — Wrap all reads and writes to `results` with `mu.Lock()`/`mu.Unlock()`, or switch to `sync.Map` for concurrent access
2. **[Critical] Replace busy poll with channel or sync.WaitGroup** — Use a channel to signal completion: `result := <-ch` instead of polling a map in a tight loop
3. **[Warning] Pass loop variable as goroutine argument** — Change to `go func(item string) { ... }(item)` to capture the current value
```
