# syntax=docker/dockerfile:1

ARG BASE_IMAGE_REGISTRY=ghcr.io
ARG BASE_IMAGE_NAME=linuxserver/baseimage-alpine
ARG BASE_IMAGE_VARIANT=3.22
ARG BASE_IMAGE=${BASE_IMAGE_REGISTRY}/${BASE_IMAGE_NAME}:${BASE_IMAGE_VARIANT}
ARG BUILD_OUTPUT_DIR=/out
ARG DUMP978_REPO_URL=https://github.com/flightaware/dump978
ARG DUMP978_REPO_BRANCH=master
ARG VCS_URL=https://github.com/blackoutsecure/docker-dump978

# ---------------------------------------------------------------------------
# Stage 1: Builder — clone dump978 and compile from source
# ---------------------------------------------------------------------------
FROM ${BASE_IMAGE} AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG BUILD_OUTPUT_DIR
ARG DUMP978_REPO_URL
ARG DUMP978_REPO_BRANCH
ARG VCS_URL

RUN apk add --no-cache \
        bash \
        boost-dev \
        ca-certificates \
        cmake \
        g++ \
        git \
        make \
        librtlsdr-dev \
        soapy-sdr-dev

WORKDIR /src

RUN git clone --branch ${DUMP978_REPO_BRANCH} --single-branch --depth 1 ${DUMP978_REPO_URL} . && \
    BUILD_DATE="$(git log -1 --format=%cI)" && \
    VERSION="$(head -1 debian/changelog 2>/dev/null | awk '{print $2}' | tr -d '()' || git rev-parse --short HEAD)" && \
    case "${VERSION}" in [0-9]*.[0-9]) VERSION="${VERSION}.0" ;; esac && \
    VCS_REF="$(git rev-parse HEAD)" && \
    printf 'BUILD_DATE=%s\nVERSION=%s\nVCS_REF=%s\nVCS_URL=%s\n' \
        "${BUILD_DATE}" "${VERSION}" "${VCS_REF}" "${VCS_URL}" \
        > /tmp/dump978-build-metadata.env && \
    rm -rf .git

# Build dump978-fa, faup978, and skyaware978
RUN . /tmp/dump978-build-metadata.env && \
    make -j"$(nproc)" VERSION="${VERSION}" dump978-fa faup978 skyaware978

# Build SoapyRTLSDR module (not packaged in Alpine 3.22+)
WORKDIR /src/SoapyRTLSDR
RUN git clone --depth 1 https://github.com/pothosware/SoapyRTLSDR.git . && \
    mkdir build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j"$(nproc)" && \
    make install DESTDIR="${BUILD_OUTPUT_DIR}"

WORKDIR /src

# Create application layout
RUN set -eux && \
    mkdir -p \
        "${BUILD_OUTPUT_DIR}/usr/bin" \
        "${BUILD_OUTPUT_DIR}/usr/share/dump978-fa" \
        "${BUILD_OUTPUT_DIR}/usr/share/skyaware978" && \
    # Install binaries
    install -m 0755 dump978-fa "${BUILD_OUTPUT_DIR}/usr/bin/dump978-fa" && \
    install -m 0755 faup978 "${BUILD_OUTPUT_DIR}/usr/bin/faup978" && \
    install -m 0755 skyaware978 "${BUILD_OUTPUT_DIR}/usr/bin/skyaware978" && \
    # Install SkyAware web assets
    cp -a skyaware/. "${BUILD_OUTPUT_DIR}/usr/share/skyaware978/" && \
    # Patch: guard createSiteCircleFeatures() against null SitePosition to
    # prevent "Cannot read properties of null" errors when location is not set
    sed -i 's/^function createSiteCircleFeatures() {/function createSiteCircleFeatures() {\n    if (!SitePosition) return;/' \
        "${BUILD_OUTPUT_DIR}/usr/share/skyaware978/script.js" && \
    # Patch: replace about:blank placeholder in flag img with transparent pixel
    # to prevent ERR_UNKNOWN_URL_SCHEME in Chrome/Edge (about: is not a valid
    # resource scheme for img src)
    sed -i 's|src="about:blank"|src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7"|' \
        "${BUILD_OUTPUT_DIR}/usr/share/skyaware978/index.html" && \
    # Install build metadata
    install -D -m 0644 /tmp/dump978-build-metadata.env \
        "${BUILD_OUTPUT_DIR}/usr/share/dump978-fa/build-metadata.env"

# ---------------------------------------------------------------------------
# Stage 2: Runtime image
# ---------------------------------------------------------------------------
FROM ${BASE_IMAGE}

ARG BUILD_OUTPUT_DIR
ARG DUMP978_USER=abc
ARG DUMP978_RAW_PORT=30978
ARG DUMP978_JSON_PORT=30979
ARG DUMP978_WEB_PORT=8978
ARG VCS_URL

LABEL build_version="Linuxserver.io version:- unknown Build-date:- unknown"
LABEL maintainer="Blackout Secure - https://blackoutsecure.app/"
LABEL org.opencontainers.image.title="docker-dump978" \
    org.opencontainers.image.description="LinuxServer.io style containerized build of dump978-fa — 978 MHz UAT decoder with SkyAware978 web UI, SoapySDR support, hardened container defaults, and switchable FlightAware / ADS-B Exchange profiles." \
    org.opencontainers.image.url="${VCS_URL}" \
    org.opencontainers.image.source="${VCS_URL}" \
    org.opencontainers.image.revision="unknown" \
    org.opencontainers.image.created="unknown" \
    org.opencontainers.image.version="unknown" \
    org.opencontainers.image.licenses="MIT"

ENV HOME="/config" \
    DUMP978_USER="${DUMP978_USER}" \
    DUMP978_PROFILE="adsbexchange" \
    DUMP978_RAW_PORT="${DUMP978_RAW_PORT}" \
    DUMP978_JSON_PORT="${DUMP978_JSON_PORT}" \
    DUMP978_WEB_PORT="${DUMP978_WEB_PORT}" \
    DUMP978_LAT="" \
    DUMP978_LON="" \
    DUMP978_STATS_URL="" \
    DUMP978_FA_STATS_URL="" \
    DUMP978_ADSBX_STATS_URL="" \
    DUMP978_SDR_PPM="" \
    DUMP978_SDR_AUTO_GAIN="true" \
    DUMP978_SDR_ANTENNA="" \
    DUMP978_SDR_DEVICE_SETTINGS="" \
    DUMP978_SDR_STREAM_SETTINGS="" \
    DUMP978_FORMAT="" \
    DUMP978_STRATUX="" \
    DUMP978_RAW_LEGACY_PORT="" \
    DUMP978_ENABLE_FAUP978="false" \
    DUMP978_TISB_FILTER=""

# Install runtime dependencies:
#   boost1.84-* — Boost 1.84 runtime libraries required by dump978-fa
#   soapy-sdr — SoapySDR runtime for SDR device access
#   rtl-sdr — RTL-SDR utilities and udev rules (SoapyRTLSDR module built from source)
#   nginx — serves the SkyAware978 web UI
#   bash — required by service scripts
RUN apk add --no-cache \
        bash \
        boost1.84-filesystem \
        boost1.84-program_options \
        boost1.84-regex \
        boost1.84-system \
        libstdc++ \
        nginx \
        rtl-sdr \
        soapy-sdr \
        tzdata

# Copy built application from builder stage
COPY --link --from=builder ${BUILD_OUTPUT_DIR}/usr/bin/ /usr/bin/
COPY --link --from=builder ${BUILD_OUTPUT_DIR}/usr/share/dump978-fa/ /usr/share/dump978-fa/
COPY --link --from=builder ${BUILD_OUTPUT_DIR}/usr/share/skyaware978/ /usr/share/skyaware978/
COPY --link --from=builder ${BUILD_OUTPUT_DIR}/usr/lib/SoapySDR/ /usr/lib/SoapySDR/

# Copy s6-overlay service definitions and nginx config template
COPY --link root/ /

# Set up application directories and configure
RUN set -eux && \
    # Load build metadata into labels if available
    if [ -f /usr/share/dump978-fa/build-metadata.env ]; then \
        . /usr/share/dump978-fa/build-metadata.env; \
    fi && \
    echo "Linuxserver.io version:- ${VERSION:-unknown} Build-date:- ${BUILD_DATE:-unknown} Revision:- ${VCS_REF:-unknown}" > /build_version && \
    # Make s6 service scripts executable
    find /etc/s6-overlay/s6-rc.d -type f \( -name run -o -name finish -o -name check \) -exec chmod 0755 {} + && \
    # Make periodic scripts executable
    find /etc/periodic -type f -exec chmod 0755 {} + && \
    # Create required directories
    mkdir -p \
        /config \
        /run/dump978-fa \
        /run/skyaware978 \
        /etc/default && \
    # Install default config files
    printf '# dump978-fa default configuration\nDUMP978_SDR="driver=rtlsdr"\nDUMP978_SDR_GAIN=""\nDUMP978_RAW_PORT="30978"\nDUMP978_JSON_PORT="30979"\nDUMP978_EXTRA_ARGS=""\n' \
        > /etc/default/dump978-fa && \
    printf '# skyaware978 default configuration\nSKYAWARE978_JSON_PORT="30979"\nSKYAWARE978_CONNECT="localhost:30978"\nSKYAWARE978_WRITE_DIR="/run/skyaware978"\nSKYAWARE978_EXTRA_ARGS=""\n' \
        > /etc/default/skyaware978 && \
    # Set ownership (after all file creation is done)
    chown -R 911:911 /config /run/dump978-fa /run/skyaware978 /usr/share/dump978-fa /usr/share/skyaware978 && \
    # Cleanup (apk cache already empty via --no-cache)
    rm -rf /tmp/* /var/tmp/*

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD sh -c 'wget -q --spider http://127.0.0.1:${DUMP978_WEB_PORT:-8978}/ && test -f /run/skyaware978/aircraft.json || exit 1'

EXPOSE ${DUMP978_RAW_PORT} ${DUMP978_JSON_PORT} ${DUMP978_WEB_PORT}
VOLUME ["/config", "/run/dump978-fa"]
