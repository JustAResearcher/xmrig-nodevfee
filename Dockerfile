FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    cmake \
    automake \
    libtool \
    autoconf \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /xmrig

COPY . /xmrig/

RUN cd /xmrig/scripts && \
    chmod +x *.sh && \
    ./build_deps.sh

RUN mkdir -p /xmrig/build && cd /xmrig/build && \
    cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_OPENCL=OFF \
    -DWITH_CUDA=OFF \
    -DWITH_HWLOC=ON \
    -DWITH_TLS=ON \
    -DWITH_ASM=ON \
    -DWITH_EMBEDDED_CONFIG=OFF \
    -DBUILD_STATIC=ON \
    -DUV_INCLUDE_DIR=/xmrig/scripts/deps/include \
    -DUV_LIBRARY=/xmrig/scripts/deps/lib/libuv.a \
    -DHWLOC_INCLUDE_DIR=/xmrig/scripts/deps/include \
    -DHWLOC_LIBRARY=/xmrig/scripts/deps/lib/libhwloc.a \
    -DOPENSSL_ROOT_DIR=/xmrig/scripts/deps && \
    make -j$(nproc)

RUN strip /xmrig/build/xmrig
