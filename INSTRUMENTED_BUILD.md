# Building an Instrumented Expanso for Local Debugging

Debug the stuck pipeline issue by adding logging to key code paths.

## 1. Clone the repo

```bash
git clone git@github.com:expanso-io/expanso.git
cd expanso
```

## 2. Add instrumentation

### orchestrator/internal/transport/dispatcher.go

Add logging around execution dispatch:

```go
// Around line 81-85 in HandleEvent
func (d *Dispatcher) HandleEvent(ctx context.Context, event watcher.Event) error {
    log.Info().
        Str("event_type", string(event.Type)).
        Str("target_node", targetNodeID).
        Str("execution_id", executionID).
        Msg("DISPATCH: Attempting to send execution assignment")

    err := d.publisher.PublishAsync(ctx, targetNodeID, msg)
    if err != nil {
        log.Error().
            Err(err).
            Str("target_node", targetNodeID).
            Str("execution_id", executionID).
            Msg("DISPATCH: Failed to send execution assignment - EVENT WILL BE SKIPPED")
    }
    return err
}
```

### orchestrator/internal/transport/manager.go

Add logging around connection checks:

```go
// Around line 158-165 in PublishAsync
func (m *Manager) PublishAsync(ctx context.Context, nodeID string, msg *envelope.Message) error {
    connection, exists := m.transport.GetConnection(nodeID)

    log.Info().
        Str("node_id", nodeID).
        Bool("connection_exists", exists).
        Bool("connection_alive", exists && connection.IsAlive()).
        Msg("PUBLISH: Checking node connection")

    if !exists || !connection.IsAlive() {
        log.Warn().
            Str("node_id", nodeID).
            Msg("PUBLISH: Node not connected - returning ErrNodeNotConnected")
        return ErrNodeNotConnected(nodeID)
    }
    // ...
}
```

### orchestrator/internal/scheduler/reconciler.go

Add logging around rollout state:

```go
// Around line 690-722
log.Info().
    Int("unscheduled_count", len(unscheduled)).
    Bool("is_wave_conclusive", e.isWaveConclusive()).
    Msg("RECONCILER: Checking rollout completion")
```

### edge/internal/controller/network_controller.go

Add logging when edge receives execution requests:

```go
// Around line 48-100
log.Info().
    Str("execution_id", req.ExecutionID).
    Msg("EDGE: Received RunExecutionRequest")
```

## 3. Build Docker images

```bash
# Build orchestrator
docker build -t expanso-orchestrator:debug -f Dockerfile.orchestrator .

# Build edge
docker build -t expanso-edge:debug -f Dockerfile.edge .
```

Or if there's a single Dockerfile:

```bash
docker build -t expanso:debug .
```

## 4. Update docker-compose to use local images

```yaml
services:
  edge1:
    image: expanso-edge:debug
    # ... rest of config
```

## 5. Run with verbose logging

```bash
docker compose up  # no -d, watch logs in terminal
```

## Key things to watch for

1. **DISPATCH: Failed to send** - execution assignment lost
2. **PUBLISH: Node not connected** - node wasn't ready when dispatch happened
3. **EDGE: Received RunExecutionRequest** - confirms edge got the message (or didn't)
4. **RECONCILER: Checking rollout** - shows if rollout is stuck waiting

## Expected failure pattern

```
# After node restart:
PUBLISH: Node not connected - node_id=<new-node-id>
DISPATCH: Failed to send execution assignment - EVENT WILL BE SKIPPED
# No "EDGE: Received RunExecutionRequest" logs
# RECONCILER shows unscheduled_count > 0, is_wave_conclusive = false
```
