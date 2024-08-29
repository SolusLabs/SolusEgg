FROM debian:buster-slim

LABEL author="Janosch | Solus Labs" maintainer="info@janosch-bl.de"

RUN apt update && apt upgrade -y && \
    apt install -y git curl tar zip unzip python3 python3-pip locales && \
    update-locale lang=de_DE.UTF-8 && \
    dpkg-reconfigure --frontend noninteractive locales && \
    useradd -m -d /home/container -s /bin/bash container

USER container

ENV USER=container HOME=/home/container
ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]
