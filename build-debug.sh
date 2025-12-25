#!/bin/bash
set -e

EXPANSO_REPO="${EXPANSO_REPO:-../expanso}"

echo "Building debug images from $EXPANSO_REPO..."
cd "$EXPANSO_REPO"

# Checkout instrumented branch if it exists
git fetch origin
if git rev-parse --verify origin/debug/instrumented-transport >/dev/null 2>&1; then
    git checkout debug/instrumented-transport
else
    echo "Note: debug/instrumented-transport branch not found, using current branch"
fi

# Build images (adjust Dockerfile paths as needed for your repo structure)
echo "Building orchestrator..."
docker build -t expanso-orchestrator:debug -f docker/orchestrator.Dockerfile . || \
docker build -t expanso-orchestrator:debug -f Dockerfile --target orchestrator .

echo "Building edge..."
docker build -t expanso-edge:debug -f docker/edge.Dockerfile . || \
docker build -t expanso-edge:debug -f Dockerfile --target edge .

echo ""
echo "Debug images built successfully!"
docker images | grep expanso | grep debug
