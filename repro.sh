#!/bin/bash
set -e

# Repro for https://github.com/expanso-io/expanso/issues/395
# Pipeline jobs stuck in 'deploying' state after node recreation

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1"; }
warn() { echo -e "${YELLOW}[$(date +%H:%M:%S)]${NC} $1"; }
error() { echo -e "${RED}[$(date +%H:%M:%S)]${NC} $1"; }
step() { echo -e "\n${CYAN}━━━ STEP $1 ━━━${NC}"; }

: "${EXPANSO_EDGE_BOOTSTRAP_TOKEN:?Set EXPANSO_EDGE_BOOTSTRAP_TOKEN from cloud.expanso.io}"
: "${EXPANSO_ENDPOINT:?Set EXPANSO_ENDPOINT (e.g. https://xxx.us1.cloud.expanso.io:9010)}"

export EXPANSO_EDGE_BOOTSTRAP_TOKEN

cleanup() {
    log "Cleaning up..."
    docker compose down -v 2>/dev/null || true
}
trap cleanup EXIT

step "1: Start 2 edge nodes"
docker compose up -d
log "Waiting for nodes to connect..."
sleep 15

step "2: Verify nodes joined"
expanso-cli node list --endpoint "$EXPANSO_ENDPOINT"

step "3: Deploy pipeline via Expanso Cloud UI"
warn ">>> Go to cloud.expanso.io and deploy a pipeline to your nodes <<<"
warn ">>> Use the content from pipelines/test-pipeline.yaml <<<"
read -p "Press Enter once pipeline is deployed and running..."

step "4: Verify job is running"
expanso-cli job list --endpoint "$EXPANSO_ENDPOINT"

step "5: Stop the pipeline"
read -p "Enter job ID to stop (or press Enter to skip): " JOB_ID
if [ -n "$JOB_ID" ]; then
    expanso-cli job stop "$JOB_ID" --endpoint "$EXPANSO_ENDPOINT" || true
fi
sleep 3

step "6: Delete edge nodes (docker rm -f)"
warn "Deleting edge containers..."
docker rm -f edge1 edge2
sleep 3

step "7: Recreate edge nodes (new NodeIDs)"
docker compose up -d
sleep 15

step "8: Verify new nodes joined"
expanso-cli node list --endpoint "$EXPANSO_ENDPOINT"

step "9: Redeploy pipeline via Expanso Cloud UI"
warn ">>> Go to cloud.expanso.io and redeploy the pipeline <<<"
read -p "Press Enter once pipeline is redeployed..."

step "10: Check job state"
error "BUG: Job likely stuck in 'deploying':"
expanso-cli job list --endpoint "$EXPANSO_ENDPOINT"

echo ""
error "━━━ EXPECTED: Job stuck in 'deploying' ━━━"
log "See: https://github.com/expanso-io/expanso/issues/395"
