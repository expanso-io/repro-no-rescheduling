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

### Build & Run

```bash
# Build Docker images from instrumented binaries
./build-debug.sh

# Start local stack (watch logs in terminal)
docker compose -f docker-compose.debug.yml up
```

### Interact with local cluster

```bash
# From your local machine (orchestrator exposes port 9010)
export EXPANSO_CLI_ENDPOINT=http://localhost:9010

# List nodes
expanso-cli node list

# Run a job
expanso-cli job run pipelines/test-pipeline.yaml

# List jobs
expanso-cli job list
```

### Reproduce the bug locally

```bash
# 1. Verify nodes connected
expanso-cli node list

# 2. Create a pipeline job
expanso-cli job run pipelines/test-pipeline.yaml

# 3. Kill edges
docker rm -f edge1-debug edge2-debug

# 4. Restart edges
docker compose -f docker-compose.debug.yml up -d edge1 edge2

# 5. Watch logs - job should be stuck
docker compose -f docker-compose.debug.yml logs -f
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
