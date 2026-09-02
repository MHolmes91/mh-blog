FROM node:22-bookworm AS node

FROM golang:1.24-bookworm

ARG HUGO_VERSION=0.159.2
ARG TARGETARCH

COPY --from=node /usr/local /usr/local

RUN apt-get update \
    && apt-get install --yes --no-install-recommends ca-certificates curl git \
    && case "${TARGETARCH}" in \
      amd64) HUGO_ARCH=Linux-64bit ;; \
      arm64) HUGO_ARCH=linux-arm64 ;; \
      *) echo "Unsupported architecture: ${TARGETARCH}" >&2; exit 1 ;; \
    esac \
    && curl --fail --location --silent --show-error \
      "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_${HUGO_ARCH}.tar.gz" \
      --output /tmp/hugo.tar.gz \
    && tar --extract --gzip --file /tmp/hugo.tar.gz --directory /usr/local/bin hugo \
    && rm /tmp/hugo.tar.gz \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN hugo mod get && hugo --gc --minify
