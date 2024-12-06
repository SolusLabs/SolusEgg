FROM eclipse-temurin:8-jdk AS java8
FROM eclipse-temurin:11-jdk AS java11
FROM eclipse-temurin:17-jdk AS java17
FROM eclipse-temurin:21-jdk AS java21

# Finale Stage
FROM debian:bullseye-slim

# Notwendige Pakete installieren (curl, wget, jq)
RUN apt-get update && apt-get install -y wget curl jq && rm -rf /var/lib/apt/lists/*

# Umgebungsvariablen für Java-Pfade
ENV JAVA8_HOME=/opt/java8
ENV JAVA11_HOME=/opt/java11
ENV JAVA17_HOME=/opt/java17
ENV JAVA21_HOME=/opt/java21

# Verzeichnisse erstellen
RUN mkdir -p $JAVA8_HOME $JAVA11_HOME $JAVA17_HOME $JAVA21_HOME

# Java-Versionen kopieren
COPY --from=java8 /opt/java/openjdk $JAVA8_HOME
COPY --from=java11 /opt/java/openjdk $JAVA11_HOME
COPY --from=java17 /opt/java/openjdk $JAVA17_HOME
COPY --from=java21 /opt/java/openjdk $JAVA21_HOME

# Standard-Java-Version setzen, z. B. Java 11
ENV JAVA_HOME=$JAVA21_HOME
ENV PATH=$JAVA_HOME/bin:$PATH

WORKDIR /home/container

COPY entrypoint.sh .

RUN chmod +x entrypoint.sh

ENTRYPOINT ["./entrypoint.sh"]
