#!/bin/bash
set -e

echo "Building debug images from local binaries in ./bin..."

# Build orchestrator
echo "Building expanso-orchestrator:debug..."
docker build -t expanso-orchestrator:debug -f docker/orchestrator.Dockerfile .

# Build edge
echo "Building expanso-edge:debug..."
docker build -t expanso-edge:debug -f docker/edge.Dockerfile .

echo ""
echo "Debug images built successfully!"
docker images | grep expanso | grep debug
