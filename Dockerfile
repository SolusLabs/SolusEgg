FROM debian:bookworm

LABEL author="Janosch | Solus Labs" maintainer="info@janosch-bl.de"

RUN sudo apt update && sudo apt upgrade -y && \
    sudo apt install -y git curl tar zip unzip python3 python3-pip locales && \
    sudo update-locale lang=de_DE.UTF-8 && \
    sudo useradd -m -d /home/container -s /bin/bash container

USER container

ENV USER=container HOME=/home/container

WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]
