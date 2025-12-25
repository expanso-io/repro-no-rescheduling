#!/bin/bash
set -e

echo "Building Docker images from instrumented binaries in ./bin..."

# Verify binaries exist
for bin in bin/expanso-orchestrator bin/expanso-edge bin/expanso-cli; do
    if [ ! -f "$bin" ]; then
        echo "Error: $bin not found"
        exit 1
    fi
done

echo "Verifying binaries are Linux..."
file bin/expanso-* | grep -q "ELF 64-bit" || {
    echo "Error: binaries must be Linux ELF format, not macOS"
    exit 1
}

echo "Building Docker images..."
docker build -t expanso-orchestrator:debug -f docker/orchestrator.Dockerfile .
docker build -t expanso-edge:debug -f docker/edge.Dockerfile .

echo ""
echo "Done!"
docker images | grep expanso | grep debug
