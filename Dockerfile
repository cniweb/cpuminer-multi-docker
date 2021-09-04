FROM  debian:11
RUN set -x \
    # Runtime dependencies.
 && apt-get update \
 && apt-get upgrade -y \
    # Build dependencies.
 && apt-get install -y \
        autoconf \
        automake \
        curl \
        g++ \
        git \
        libcurl4-openssl-dev \
        libjansson-dev \
        libssl-dev \
        libgmp-dev \
        libz-dev \
        make \
        pkg-config
RUN set -x \
    # Compile from source code.
 && git clone --recursive https://github.com/tpruvot/cpuminer-multi.git -b linux /tmp/cpuminer \
 && cd /tmp/cpuminer \
 && ./autogen.sh \
 && extracflags="$extracflags -Ofast -flto -fuse-linker-plugin -ftree-loop-if-convert-stores" \
 && CFLAGS="-O2 $extracflags -DUSE_ASM -pg" ./configure --with-crypto --with-curl \
 && make install -j 4 \
    # Clean-up
 && cd / \
 && apt-get purge --auto-remove -y \
        autoconf \
        automake \
        curl \
        g++ \
        git \
        make \
        pkg-config \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /tmp/* \
    # Verify
 && cpuminer --cputest \
 && cpuminer --version

WORKDIR /cpuminer
COPY config.json /cpuminer
CMD ["cpuminer", "--config=config.json"]