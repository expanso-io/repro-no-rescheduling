# Issue #395 Unit Tests

These tests document the bug behavior for [expanso-io/expanso#395](https://github.com/expanso-io/expanso/issues/395).

## Usage

To run these tests, copy `issue395_test.go` to the expanso repository:

```bash
cp issue395_test.go /path/to/expanso/orchestrator/internal/scheduler/
cd /path/to/expanso
go test -v -tags=unit ./orchestrator/internal/scheduler/... -run TestIssue395
```

## Test Groups

| Test | Documents |
|------|-----------|
| `TestIssue395_StuckPending_*` | Pending executions NOT re-dispatched on node reconnect |
| `TestIssue395_CascadingFailure_*` | Stuck pending blocks ALL future jobs to that node |
| `TestIssue395_FiveMinuteWindow_*` | The 5-minute disconnect detection window scenario |
| `TestIssue395_OpsJobsVsDaemonJobs` | Different behavior between ops and daemon jobs |
| `TestIssue395_AcceptanceCriteria` | Expected behavior AFTER fix (currently skipped) |

## Test Philosophy

These tests **document** the bug, not fix it. They pass when showing buggy behavior.
The acceptance criteria tests are skipped and will fail until the fix is implemented.
