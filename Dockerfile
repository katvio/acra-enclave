FROM debian:bullseye-slim AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    apt-transport-https \
    && wget -qO - https://pkgs-ce.cossacklabs.com/gpg | apt-key add - \
    && echo "deb https://pkgs-ce.cossacklabs.com/stable/debian bullseye main" > /etc/apt/sources.list.d/cossacklabs.list \
    && apt-get update \
    && apt-get install -y \
    libthemis-dev \
    acra \
    && rm -rf /var/lib/apt/lists/*

FROM debian:bullseye-slim

# Copy necessary files from builder
COPY --from=builder /usr/bin/acra-server /usr/bin/acra-server
COPY --from=builder /usr/lib/x86_64-linux-gnu/libthemis.so.* /usr/lib/x86_64-linux-gnu/
COPY --from=builder /usr/lib/x86_64-linux-gnu/libsoter.so.* /usr/lib/x86_64-linux-gnu/

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libssl1.1 \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY ./acra-server.yaml /config/acra-server.yaml
COPY ./searchable.yaml /config/searchable.yaml

# Copy and process the encrypted master key
COPY ./keys/encrypted_master_key.b64 /keys/encrypted_master_key.b64
RUN base64 -d /keys/encrypted_master_key.b64 > /keys/encrypted_master_key && \
    chmod 400 /keys/encrypted_master_key && \
    rm /keys/encrypted_master_key.b64

# Copy the entrypoint script
COPY entrypoint.sh /config/entrypoint.sh
RUN chmod +x /config/entrypoint.sh

# Set library path
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

ENTRYPOINT ["/config/entrypoint.sh"]