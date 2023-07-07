# syntax=docker/dockerfile:1

FROM "ubuntu:jammy-20230301"
ARG SCRIPT_SOURCE="https://raw.githubusercontent.com/zaldanaraul/vagrantize-docker/v0.0.1/vagrantize-docker.sh"
ARG USERNAME="testuser"
ARG PASSWORD="testpass"
# Install sudo
RUN apt-get update && apt-get install sudo
# Add custom user
RUN useradd --create-home --groups=sudo --shell="/bin/bash" "${USERNAME}"
RUN echo "$USERNAME:$PASSWORD" | chpasswd
USER ${USERNAME}
ADD --chown=${USERNAME} --chmod=0700 ${SCRIPT_SOURCE} vagrantize-docker.sh
RUN ./vagrantize-docker.sh --user="${USERNAME}" --password="${PASSWORD}"

