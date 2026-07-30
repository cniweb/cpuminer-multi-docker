FROM debian:trixie-slim

# Set non-root user early
ARG VERSION_TAG=v1.3.1-multi
ARG CPUMINER_USER=cpuminer
ARG CPUMINER_UID=1000
ARG CPUMINER_GID=1000

# Environment variables for mining configuration (no sensitive data in ENV)
ENV ALGO="scrypt"
ENV POOL_ADDRESS="stratum+tcp://pool.example.com:3333"
ENV WALLET_USER="YOUR_WALLET_ADDRESS"
ENV PASSWORD="x"

# Create non-root user and group
RUN set -eu && groupadd -g ${CPUMINER_GID} ${CPUMINER_USER} \
    && useradd -u ${CPUMINER_UID} -g ${CPUMINER_GID} -m -s /usr/sbin/nologin ${CPUMINER_USER}

# Install runtime and build dependencies, compile from source
RUN set -eu \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        ca-certificates \
        curl \
        g++ \
        git \
        libcurl4-openssl-dev \
        libgmp-dev \
        libjansson-dev \
        libssl-dev \
        libz-dev \
        make \
        pkg-config \
    && update-ca-certificates \
    # Compile from source code.
    && git clone --recursive https://github.com/tpruvot/cpuminer-multi.git -b linux /tmp/cpuminer \
    && cd /tmp/cpuminer \
    && ./autogen.sh \
    && extracflags="-Ofast -flto -fuse-linker-plugin -ftree-loop-if-convert-stores" \
    && CFLAGS="-O2 $extracflags -DUSE_ASM -pg" ./configure --with-crypto --with-curl \
    && make install -j 4 \
    # Clean-up build dependencies
    && cd / \
    && apt-get purge --auto-remove -y \
        autoconf \
        automake \
        curl \
        g++ \
        git \
        make \
        pkg-config \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/* /tmp/* /var/tmp/*

# Switch to non-root user
USER ${CPUMINER_USER}
WORKDIR /cpuminer
COPY --chown=${CPUMINER_USER}:${CPUMINER_USER} config.json /cpuminer

# Use non-privileged port
EXPOSE 8080

ENV PATH="/usr/local/bin:${PATH}"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD cpuminer --version || exit 1

CMD ["cpuminer", "--config=config.json"]