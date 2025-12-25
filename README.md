# Repro: Pipeline Jobs Stuck in 'deploying' State

Minimal reproduction for [expanso-io/expanso#395](https://github.com/expanso-io/expanso/issues/395).

## The Bug

Pipeline jobs get stuck in `deploying` state indefinitely when edge nodes are deleted and recreated. The job shows executions created but no progress toward completion.

## Prerequisites

- Docker
- `expanso-cli` installed
- Expanso Cloud account at [cloud.expanso.io](https://cloud.expanso.io)

## Setup

1. Copy `.env.example` to `.env`
2. Add your bootstrap token from cloud.expanso.io

## Files

```
├── docker-compose.yml          # 2 edge nodes
├── pipelines/test-pipeline.yaml # Sample pipeline
├── repro.sh                    # Interactive repro script
└── .env                        # Your credentials
```

## Pipeline

Use this in the Expanso Cloud UI:

```yaml
input:
  generate:
    count: 0
    interval: 30s
    mapping: |
      root.message = "heartbeat"
      root.timestamp = now()
      root.hostname = env("HOSTNAME")

pipeline:
  processors:
    - mapping: |
        root = this

output:
  stdout:
    codec: lines
```

## Reproduce

```bash
# 1. Start edge nodes
docker compose up -d && sleep 15

# 2. Verify nodes connected
expanso-cli node list --endpoint $EXPANSO_ENDPOINT

# 3. Deploy pipeline via cloud.expanso.io UI
#    Create pipeline, deploy to edge nodes, verify running

# 4. Stop the pipeline
expanso-cli job stop <job-id> --endpoint $EXPANSO_ENDPOINT

# 5. Delete nodes (must use rm -f for new NodeIDs)
docker rm -f edge1 edge2

# 6. Recreate nodes
docker compose up -d && sleep 15

# 7. Redeploy pipeline via UI
#    BUG: Job stuck in 'deploying'!
expanso-cli job list --endpoint $EXPANSO_ENDPOINT
```

Or run `./repro.sh` for an interactive walkthrough.

## Root Cause

The dispatcher uses `RetryStrategySkip` when sending execution assignments. If `PublishAsync()` fails (node not connected yet after recreation), events are permanently lost.

No recovery mechanism exists:
- No periodic re-sync of pending executions
- No pull mechanism for edges to request assigned work
- No catchup on reconnect

## Cleanup

```bash
docker compose down -v
```
