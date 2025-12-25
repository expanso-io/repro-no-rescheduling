# Repro: Pipeline Jobs Stuck in 'deploying' State

Minimal reproduction for [expanso-io/expanso#395](https://github.com/expanso-io/expanso/issues/395).

## The Bug

After edge nodes are killed and restarted, pipeline jobs no longer schedule or respond to updates.

## Reproduce

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
