# Repro: Pipeline Jobs Stuck in 'deploying' State

Minimal reproduction for [expanso-io/expanso#395](https://github.com/expanso-io/expanso/issues/395).

## The Bug

After edge nodes are killed and restarted, pipeline jobs no longer schedule or respond to updates.

## Reproduce (Against Expanso Cloud)

```bash
# Setup
cp .env.example .env  # add your bootstrap token
docker compose up -d

# 1. Create nodes ✓
expanso-cli node list --endpoint $EXPANSO_ENDPOINT

# 2. Schedule job via UI → works ✓

# 3. Update job via UI → works ✓

# 4. Kill nodes
docker rm -f edge1 edge2

# 5. Start nodes
docker compose up -d

# 6. Job doesn't auto-schedule ✗

# 7. Job updates don't schedule ✗
```

## Root Cause

Dispatcher uses `RetryStrategySkip` - execution assignments are lost when nodes aren't connected, with no recovery mechanism.

## Cleanup

```bash
docker compose down -v
```

---

## Reproduce (Local Instrumented Build)

Use locally-built debug images with added logging to trace the issue.

### Build Debug Images

```bash
# Option 1: Build from expanso repo
EXPANSO_REPO=../expanso ./build-debug.sh

# Option 2: Use pre-built binaries in ./bin
# (if you have local binaries, create images from them)
```

### Run Local Debug Stack

```bash
# Start local orchestrator + NATS + edges (no -d, watch logs)
docker compose -f docker-compose.debug.yml up

# In another terminal, reproduce:
# 1. Check nodes connected
docker exec -it orchestrator-debug expanso-cli node list

# 2. Create a job
docker exec -it orchestrator-debug expanso-cli job run /path/to/job.yaml

# 3. Kill edges
docker rm -f edge1-debug edge2-debug

# 4. Restart edges
docker compose -f docker-compose.debug.yml up edge1 edge2

# 5. Watch logs for failure pattern
```

### Log Patterns to Watch

**Success path:**
```
DISPATCH: Attempting to send message
PUBLISH: connection_exists=true connection_alive=true
EDGE: Received RunExecutionRequest
```

**Failure path (execution lost):**
```
PUBLISH: Node not connected - returning ErrNodeNotConnected
DISPATCH: Failed to send message - EVENT WILL BE SKIPPED
# (No EDGE logs = message never arrived)
RECONCILER: unscheduled_count > 0
```

### Debug Cleanup

```bash
docker compose -f docker-compose.debug.yml down -v
```
