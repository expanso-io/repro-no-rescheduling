FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY bin/expanso-orchestrator /usr/local/bin/expanso-orchestrator
COPY bin/expanso-cli /usr/local/bin/expanso-cli
RUN chmod +x /usr/local/bin/expanso-orchestrator /usr/local/bin/expanso-cli
ENTRYPOINT ["/usr/local/bin/expanso-orchestrator"]
