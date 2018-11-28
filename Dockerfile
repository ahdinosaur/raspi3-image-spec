FROM debian:buster

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && \
    apt-get -y install qemu-user-static qemu-utils \
      dosfstools \
      vmdb2 \
    && rm -rf /var/lib/apt/lists/*

COPY . /raspi/

VOLUME [ "/raspi/work", "/raspi/output"]
