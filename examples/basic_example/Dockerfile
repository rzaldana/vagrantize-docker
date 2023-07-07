# syntax=docker/dockerfile:1

FROM "ubuntu:jammy-20230301"
ARG SCRIPT_SOURCE="https://raw.githubusercontent.com/zaldanaraul/vagrantize-docker/v0.0.1/vagrantize-docker.sh"
ADD --chown=0 --chmod=0700 ${SCRIPT_SOURCE} vagrantize-docker.bash
RUN ./vagrantize-docker.bash

