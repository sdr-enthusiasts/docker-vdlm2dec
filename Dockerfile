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
COPY ./bin/acars-bridge.armv7/acars-bridge /opt/acars-bridge.armv7
COPY ./bin/acars-bridge.arm64/acars-bridge /opt/acars-bridge.arm64
COPY ./bin/acars-bridge.amd64/acars-bridge /opt/acars-bridge.amd64

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
  # ensure binaries are executable
  chmod -v a+x \
  /opt/acars-bridge.armv7 \
  /opt/acars-bridge.arm64 \
  /opt/acars-bridge.amd64 \
  && \
  # remove foreign architecture binaries
  /rename_current_arch_binary.sh && \
  rm -fv \
  /opt/acars-bridge.* \
  && \
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
  # grab the bias t scripts
  curl -o /etc/s6-overlay/scripts/00-rtlsdr-biastee-init https://raw.githubusercontent.com/sdr-enthusiasts/sdre-bias-t-common/main/09-rtlsdr-biastee-init && \
  curl -o /etc/s6-overlay/scripts/00-rtlsdr-biastee-down  https://raw.githubusercontent.com/sdr-enthusiasts/sdre-bias-t-common/main/09-rtlsdr-biastee-down && \
  chmod +x /etc/s6-overlay/scripts/00-rtlsdr-biastee-init && \
  chmod +x /etc/s6-overlay/scripts/00-rtlsdr-biastee-down && \
  # Clean up
  apt-get remove -y "${TEMP_PACKAGES[@]}" && \
  apt-get autoremove -y && \
  rm -rf /src/* /tmp/* /var/lib/apt/lists/*

# ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
