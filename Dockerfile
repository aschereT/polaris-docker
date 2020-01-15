FROM alpine:latest AS builder

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN apk add -U git make binutils pkgconfig openssl-dev sqlite-dev curl build-base gcc && \
    curl https://sh.rustup.rs -sSf | sh -s -- --default-toolchain nightly --profile=minimal -y

RUN git clone --depth=1 --recurse-submodules -j`nproc` https://github.com/agersant/polaris.git \
    && cd polaris \
    && git submodule update --recursive --remote \
    && mkdir -p release/ \
    && cp -r web docs/swagger src migrations Cargo.toml Cargo.lock res/unix/Makefile release/

RUN cd /polaris/release \
    && cargo update \
    && RUSTFLAGS="-C target-feature=-crt-static" cargo build --bins --all-features --release

RUN mkdir -p /polaris-share \
    && mkdir -p /polaris-built \
    && cp -r /polaris/release/swagger/ /polaris-share \
    && cp -r /polaris/release/web/ /polaris-share \
    && cp /polaris/release/target/release/polaris* /polaris-built

FROM alpine:latest AS final

WORKDIR /polaris

RUN apk add -U --no-cache openssl sqlite
COPY --from=builder /polaris-share /root/share/polaris
COPY --from=builder /polaris-built .
ADD run-polaris .

EXPOSE 5050
VOLUME ["/music", "/var/lib/polaris"]
CMD ["/polaris/run-polaris"]