# Docker acarsdec

![Banner](https://github.com/sdr-enthusiasts/docker-acarshub/blob/16ab3757986deb7c93c08f5c7e3752f54a19629c/Logo-Sources/ACARS%20Hub.png "banner")
[![GitHub Workflow Status](https://img.shields.io/github/workflow/status/fredclausen/docker-acarshub/Deploy%20to%20Docker%20Hub)](https://github.com/sdr-enthusiasts/docker-acarshub/actions?query=workflow%3A%22Deploy+to+Docker+Hub%22)
[![Docker Pulls](https://img.shields.io/docker/pulls/fredclausen/acarshub.svg)](https://hub.docker.com/r/fredclausen/acarshub)
[![Docker Image Size (tag)](https://img.shields.io/docker/image-size/fredclausen/acarshub/latest)](https://hub.docker.com/r/fredclausen/acarshub)
[![Discord](https://img.shields.io/discord/734090820684349521)](https://discord.gg/sTf9uYF)

Docker container for running [vdlm2dec](https://github.com/TLeconte/vdlm2dec) and forwarding the received JSON messages to another system or docker container. Best used alongside [ACARS Hub](https://github.com/fredclausen/acarshub).

Builds and runs on `amd64`, `arm64`, `arm/v7`, `arm/v6` and `386` architectures.

## Note for Users running 32-bit Debian Buster-based OSes on ARM

Please see: [Buster-Docker-Fixes](https://github.com/fredclausen/Buster-Docker-Fixes)!

## Required hardware

A computer host on a suitable architecture and one USB RTL-SDR dongle connected to an antenna.

## Up and running

```yaml
version: "2.0"

services:
  vdlm2dec:
    image: ghcr.io/sdr-enthusiasts/docker-vdlm2dec:latest
    container_name: vdlm2dec
    restart: always
    device_cgroup_rules:
      - "c 189:* rwm"
    ports:
    environment:
      - TZ="America/Denver"
      - SERIAL=13305
      - FEED_ID=VDLM
      - FREQUENCIES=130.025;130.450;131.125;131.550
    tmpfs:
      - /run:exec,size=64M
      - /var/log
    volumes:
      - /dev:/dev:ro
```

## Configuration options

| Variable                 | Description                                                                                                               | Required | Default        |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------- | -------- | -------------- |
| `TZ`                     | Your timezone                                                                                                             | No       | UTC            |
| `SERIAL`                 | The serial number of your RTL-SDR dongle                                                                                  | Yes      | Blank          |
| `FEED_ID`                | Used by the decoder to insert a unique ID in to the output message                                                        | Yes      | Blank          |
| `FREQUENCIES`            | Colon-separated list of frequencies, but to a maximum of 8, for the decoder to list to                                    | Yes      | Blank          |
| `PPM`                    | Parts per million correction of the decoder                                                                               | No       | 0              |
| `GAIN`                   | The gain applied to the RTL-SDR dongle. If you want to set the gain manually it is set in tenth of db (ie -g 90 for +9db) | No       | `400`          |
| `OUTPUT_SERVER`          | The server where messages will be forwarded to.                                                                           | No       | `acars_router` |
| `OUTPUT_SERVER_PORT`     | The port where the server will receive messages on.                                                                       | No       | `5555`         |
| `OUTPUT_SERVER_MODE`     | The output mode. `udp`, `tcp` and `zmq` are valid                                                                         | No       | `udp`          |
| `MODE`                   | The output mode. `P` for planeplotter, `J` for JSON and `A` for acarsdec.                                                 | No       | `J`            |
| `QUIET_LOGS`             | Mute log output to the bare minimum. Set to `false` to disable.                                                           | No       | `TRUE`         |
| `VDLM2DEC_COMMAND_EXTRA` | Additional arguments to pass to the decoder.                                                                              | No       | Blank          |

## Output modes

TL;DR: No change to your setup is necessary for continued functionality, but you should update your configuration to use the new variables and at least use TCP.

A recent change in the container has meant we are migrating from `SERVER`/`SERVER_PORT` to `OUTPUT_SERVER`/`OUTPUT_SERVER_PORT` as a better name for what the variable is representing. The old variables will continue to work for the time being, but please update your configuration to use the new variables. Simply replace `SERVER` with `OUTPUT_SERVER` and `SERVER_PORT` with `OUTPUT_SERVER_PORT`. If you do not have `SERVER`/`SERVER_PORT` set, you do not need to do anything and it will work as it did before.

Generally speaking for a proper migration, whatever your `SERVER` was before should be set in your compose as `OUTPUT_SERVER` and whatever your `SERVER_PORT` was before should be set as `OUTPUT_SERVER_PORT`. If `SERVER` was not set, you do not have to add in `OUTPUT_SERVER`. If you did not have `SERVER_PORT` set in your compose, you do not have to add in `OUTPUT_SERVER_PORT` unless you want to use `zmq`.

Additionally, the `OUTPUT_SERVER_MODE` variable has been added to allow for the output mode to be set. The default is `udp` and the container will function as it did before. `tcp` and `zmq` are also valid options and recommended over `udp` for reliability.

To use `tcp` with `acars_router` with the default ports it would have mapped, simply set `OUTPUT_SERVER_MODE=tcp` and leave the `OUTPUT_SERVER_PORT` as `5555` or unset.

If you wish to use `zmq` with `acars_router` with the default ports it would have mapped, simply set `OUTPUT_SERVER_MODE=zmq` and set `OUTPUT_SERVER_PORT` as `35555`.
