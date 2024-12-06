# Optional: Basis-Image für Java 21 hinzufügen
FROM openjdk:21-jdk AS java21

# Finale Stage
FROM debian:bullseye-slim

# Notwendige Pakete installieren
RUN apt-get update && apt-get install -y wget curl jq && rm -rf /var/lib/apt/lists/*

# Umgebungsvariablen für Java-Pfade
ENV JAVA21_HOME=/opt/java21

# Verzeichnisse für die verschiedenen Java-Versionen erstellen
RUN mkdir -p $JAVA21_HOME

# Java 21 kopieren
COPY --from=java21 /usr/local/openjdk-21 $JAVA21_HOME

# Standard-Java-Version setzen (z. B. Java 21)
ENV JAVA_HOME=$JAVA27_HOME
ENV PATH=$JAVA_HOME/bin:$PATH

# Arbeitsverzeichnis festlegen
WORKDIR /home/container

# Startskript kopieren
COPY entrypoint.sh .

# Startskript ausführbar machen
RUN chmod +x entrypoint.sh

# Startbefehl
ENTRYPOINT ["./entrypoint.sh"]
