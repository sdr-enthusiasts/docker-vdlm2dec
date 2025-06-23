FROM ghcr.io/sdr-enthusiasts/acars-bridge:latest AS builder
FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder

ENV DEVICE_INDEX="" \
    QUIET_LOGS="TRUE" \
    FREQUENCIES="" \
    FEED_ID="" \
    PPM="0"\
    GAIN="400" \
    SERIAL="" \
    OUTPUT_SERVER="acars_router" \
    OUTPUT_SERVER_PORT="5555" \
    OUTPUT_SERVER_MODE="udp" \
    MODE="J"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
COPY ./rootfs /
COPY --from=builder /acars-bridge /opt/acars-bridge

# hadolint ignore=DL3008,SC2086,SC2039,SC3054
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Required for building multiple packages.
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(pkg-config) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(automake) && \
    TEMP_PACKAGES+=(autoconf) && \
    TEMP_PACKAGES+=(wget) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}"\
    && \
    chmod +x /opt/acars-bridge && \
    # vdlm2dec
    # git clone https://github.com/TLeconte/vdlm2dec.git /src/vdlm2dec && \
    git clone https://github.com/wiedehopf/vdlm2dec.git /src/vdlm2dec && \
    pushd /src/vdlm2dec && \
    # fix for floating point amd64 nonsense
    sed -i 's/add_compile_options(-Ofast -march=native )/add_compile_options(-O2 )/g' CMakeLists.txt && \
    mkdir build && \
    pushd build && \
    cmake ../ -Drtl=ON -DCMAKE_BUILD_TYPE=Debug && \
    make && \
    make install && \
    popd && popd && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*

# ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
