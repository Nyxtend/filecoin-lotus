FROM ubuntu:latest

# Rough instructions derived from
# https://docs.filecoin.io/get-started/lotus/installation/#linux

# Install dependencies
RUN apt-get update && \
  DEBIAN_FRONTEND=noninteractive apt-get upgrade -qqy && \
  DEBIAN_FRONTEND=noninteractive apt-get install -qqy \
    build-essential \
    bzr \
    ca-certificates \
    clang \
    curl \
    gcc \
    git \
    gpg \
    hwloc \
    jq \
    libhwloc-dev \
    mesa-opencl-icd \
    ocl-icd-opencl-dev \
    pkg-config \
    rename \
    sudo \
    tar \
    wget

# Lotus requires rustup and go version 1.16+
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
  wget -c https://golang.org/dl/go1.16.4.linux-amd64.tar.gz -O - | tar -xz -C /usr/local

# Add go and cargo to the path
ENV PATH="${PATH}:/usr/local/go/bin:/root/.cargo/bin"

# Setup working environment
RUN mkdir -p /work
WORKDIR /work

# Clone the repo and select the most recent release
RUN git clone https://github.com/filecoin-project/lotus.git
WORKDIR /work/lotus
RUN git checkout v1.13.0

# Set flags to take advantage of zen processor capabilites
ENV RUSTFLAGS="-C target-cpu=native -g"
ENV FFI_BUILD_FROM_SOURCE=1

# Build lotus
RUN ls -ailh /root/.cargo
RUN make clean all && \
  make install && \
  lotus --version

# Add startup script
WORKDIR /work
ADD docker-init.sh .
RUN chmod +x docker-init.sh

# ENVIRONMENT VARIABLES & CONFIGURATION
# The options below can be changed to alter the default behavior of
# the lotus startup script.

# SYNC_FROM_BOOTSTRAP_IF_UNINITIALIZED
#   Lotus takes a very long time to sync on the first run. By default the
#   docker-init.sh script will use the official mainnet export to bootstrap lotus.
#   This sigificantly speeds  up sync time. Set to false to disable and perform a full node sync.
ENV SYNC_FROM_BOOTSTRAP_IF_UNINITIALIZED=true

# Expose the lotus data and log folders as volumes, these should be persisted
VOLUME [ "/root/.lotus", "/data/lotus/log" ]
EXPOSE 6665
CMD ["/work/docker-init.sh"]
