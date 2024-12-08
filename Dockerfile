FROM eclipse-temurin:21-jdk AS java21

FROM debian:bullseye-slim

LABEL version="latest"
LABEL author="Janosch | Solus Labs" maintainer="info@janosch-bl.de"

RUN apt-get update && apt-get install -y wget curl jq bash ca-certificates && rm -rf /var/lib/apt/lists/*

ENV JAVA21_HOME=/opt/java21

RUN mkdir -p $JAVA21_HOME

ENV JAVA_HOME=$JAVA21_HOME
ENV PATH=$JAVA_HOME/bin:$PATH

RUN useradd -m -d /home/container -s /bin/bash container

COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN chown -R container:container /home/container

USER container
ENV USER=container HOME=/home/container

WORKDIR /home/container

CMD ["/bin/bash", "/entrypoint.sh"]
