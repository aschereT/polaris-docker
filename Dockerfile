FROM rust:alpine AS builder

WORKDIR /

RUN apk add --no-cache git make \
    && git clone --depth=1 --recurse-submodules -j`nproc` https://github.com/agersant/polaris.git \
    && rm -rf /polaris/.git \
    && cd polaris \
    && chmod +x build_release_unix.sh \
    && ./build_release_unix.sh