# Repro: Pipeline Jobs Stuck in 'deploying' State

Minimal reproduction for [expanso-io/expanso#395](https://github.com/expanso-io/expanso/issues/395).

## The Bug

Jobs deployed **while nodes are disconnected** get stuck permanently in `deploying` state.

The dispatcher sends execution requests to nodes that aren't connected, the messages are lost, and there's no retry mechanism when nodes reconnect.

## Root Cause

Dispatcher uses `RetryStrategySkip` - execution assignments are lost when nodes aren't connected. When nodes reconnect:
1. Reevaluator creates new evaluations (trigger=node-join)
2. Scheduler sees executions already exist (desired=running, state=pending)
3. No re-dispatch occurs - the execution messages were already "sent"
4. Job stuck forever in `deploying` with executions in `pending`

---

## Reproduce (Local Instrumented Build)

Use locally-built debug images with added logging to trace the issue.

### Prerequisites

Place cross-compiled Linux binaries in `./bin`:
- `bin/expanso-orchestrator`
- `bin/expanso-edge`
- `bin/expanso-cli`

### Build & Run

```bash
# Build Docker images from instrumented binaries
./build-debug.sh

# Start local stack (in background)
docker compose -f docker-compose.debug.yml up -d
```

### Reproduce the bug

```bash
# 1. Verify nodes connected
docker exec orchestrator-debug expanso-cli node list

# 2. Deploy a working job (optional - proves things work)
docker cp pipelines/test-job.yaml orchestrator-debug:/tmp/
docker exec orchestrator-debug expanso-cli job deploy /tmp/test-job.yaml
docker exec orchestrator-debug expanso-cli execution list
# Executions should be "running"

# 3. Kill edges
docker rm -f edge1-debug edge2-debug

# 4. Deploy NEW job while edges are dead
docker cp pipelines/new-job.yaml orchestrator-debug:/tmp/
docker exec orchestrator-debug expanso-cli job deploy /tmp/new-job.yaml

# 5. Restart edges
docker compose -f docker-compose.debug.yml up -d edge1 edge2
sleep 20  # Wait for reevaluator batch (15s delay)

# 6. Check state - new job is STUCK
docker exec orchestrator-debug expanso-cli job list
# new-test-job shows "deploying" instead of "running"

docker exec orchestrator-debug expanso-cli execution list
# new-test-job executions show state=pending, desired=running
```

### Expected vs Actual

**Expected:** After nodes reconnect, scheduler should re-dispatch execution requests for pending executions.

**Actual:** Executions remain in `pending` state forever. The dispatch event was consumed and lost.

### Log Patterns to Watch

```bash
docker logs orchestrator-debug 2>&1 | grep -E "(DISPATCH|PUBLISH|leave)"
```

**Success path (nodes connected):**
```
DISPATCH: Attempting to send message
PUBLISH: connection_exists=true connection_alive=true
```

**Failure path (nodes dead but orchestrator doesn't know yet):**
```
DISPATCH: Attempting to send message
PUBLISH: connection_exists=true connection_alive=true
# (Message sent to NATS but no subscriber - lost forever)
```

**Recovery that doesn't happen:**
```
REEVALUATOR: Created evaluation for job (trigger=node-join)
# Scheduler processes evaluation but doesn't re-dispatch
# No new DISPATCH logs for the stuck job
```

### Debug Cleanup

```bash
docker compose -f docker-compose.debug.yml down -v
```

---

## Reproduce (Against Expanso Cloud)

```bash
# Setup
cp .env.example .env  # add your bootstrap token
docker compose up -d

# 1. Create nodes
expanso-cli node list --endpoint $EXPANSO_ENDPOINT

# 2. Schedule job via UI -> works

# 3. Kill nodes
docker rm -f edge1 edge2

# 4. Deploy NEW job via UI while nodes dead

# 5. Start nodes
docker compose up -d

# 6. Job stuck in deploying
```

### Cleanup

```bash
docker compose down -v
```
