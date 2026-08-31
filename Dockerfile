FROM debian:bookworm-slim

ARG UID=1000
ARG GID=1000
ARG OC_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive

# TUNA mirror. bookworm-slim ships no ca-certificates, so bootstrap it with
# TLS peer verification disabled (apt still verifies the signed InRelease,
# so packages remain authenticated).
RUN rm -f /etc/apt/sources.list.d/debian.sources \
 && printf '%s\n' \
      'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free non-free-firmware' \
      'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free non-free-firmware' \
      'deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-backports main contrib non-free non-free-firmware' \
      > /etc/apt/sources.list \
 && apt-get -o Acquire::https::Verify-Peer=false -o Acquire::https::Verify-Host=false update \
 && apt-get -o Acquire::https::Verify-Peer=false -o Acquire::https::Verify-Host=false install -y --no-install-recommends ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      bash \
      bash-completion \
      bat \
      build-essential \
      ca-certificates \
      curl \
      dnsutils \
      fd-find \
      file \
      git \
      htop \
      iproute2 \
      jq \
      less \
      net-tools \
      openssh-client \
      procps \
      python3 \
      ripgrep \
      tar \
      tcpdump \
      tmux \
      tree \
      unzip \
      vim \
      wget \
      xz-utils \
      zip \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s /usr/bin/batcat /usr/local/bin/bat \
 && ln -s /usr/bin/fdfind /usr/local/bin/fd

# just 只在 bookworm-backports（sources.list 已启用）
RUN apt-get update \
 && apt-get install -y -t bookworm-backports --no-install-recommends just \
 && rm -rf /var/lib/apt/lists/*

RUN groupadd -g ${GID} dev \
 && useradd -m -u ${UID} -g ${GID} -s /bin/bash dev

COPY toolchains/entrypoint.sh /usr/local/bin/ocbox-entrypoint
RUN chmod +x /usr/local/bin/ocbox-entrypoint

USER dev

ARG INSTALL_PROXY=

# flaky network: force HTTP/1.1 + retries for every curl (incl. install script)
RUN printf 'http1.1\nretry 5\nretry-all-errors\nconnect-timeout 15\n' > /home/dev/.curlrc

# opencode binary is fetched from GitHub releases, which may need a proxy
# (apt uses the TUNA mirror directly). INSTALL_PROXY is scoped to this step only.
RUN if [ -n "${INSTALL_PROXY}" ]; then \
      export http_proxy="${INSTALL_PROXY}" https_proxy="${INSTALL_PROXY}" all_proxy="${INSTALL_PROXY}"; \
    fi; \
    if [ "${OC_VERSION}" = "latest" ]; then \
      curl -fsSL https://opencode.ai/install | bash; \
    else \
      curl -fsSL https://opencode.ai/install | bash -s -- "${OC_VERSION}"; \
    fi

ENV PATH="/home/dev/.opencode/bin:${PATH}"
ENV OPENCODE_DISABLE_AUTOUPDATE=1

ENTRYPOINT ["/usr/local/bin/ocbox-entrypoint"]

WORKDIR /workspace
CMD ["opencode"]
