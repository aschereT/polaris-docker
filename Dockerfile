FROM ubuntu:rolling AS builder

WORKDIR /

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN apt update && apt install -y git make binutils pkg-config libssl-dev libsqlite3-dev curl \
    && rm -rf /var/lib/apt/lists/* \
    && curl https://sh.rustup.rs -sSf | bash -s -- --default-toolchain nightly -y

RUN git clone --depth=1 --recurse-submodules -j`nproc` https://github.com/agersant/polaris.git \
    && cd polaris \
    && git submodule update --recursive --remote \
    && mkdir -p release/ \
    && cp -r web docs/swagger src migrations Cargo.toml Cargo.lock res/unix/Makefile release/

RUN cd /polaris/release \
    && cargo build --bins --all-features --release

RUN mkdir -p /polaris-share \
    && mkdir -p /polaris-built \
    && cp -r /polaris/release/swagger/ /polaris-share \
    && cp -r /polaris/release/web/ /polaris-share \
    && cp /polaris/release/target/release/polaris* /polaris-built

FROM ubuntu:rolling AS final

WORKDIR /polaris

RUN apt update && apt install -y libssl1.1 libsqlite3-0 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /polaris-share /root/share/polaris
COPY --from=builder /polaris-built .
ADD run-polaris .

EXPOSE 5050
VOLUME ["/music", "/var/lib/polaris"]
CMD ["/polaris/run-polaris"]