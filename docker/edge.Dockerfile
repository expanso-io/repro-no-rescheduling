FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates docker.io && rm -rf /var/lib/apt/lists/*
COPY bin/expanso-edge /usr/local/bin/expanso-edge
RUN chmod +x /usr/local/bin/expanso-edge
ENTRYPOINT ["/usr/local/bin/expanso-edge"]
