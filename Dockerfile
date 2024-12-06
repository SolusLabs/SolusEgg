# Basis-Image für Java 8
FROM openjdk:8-jdk AS java8

# Basis-Image für Java 11
FROM openjdk:11-jdk AS java11

# Basis-Image für Java 17
FROM openjdk:17-jdk AS java17

# Finale Stage
FROM debian:bullseye-slim

# Umgebungsvariablen für Java-Pfade
ENV JAVA8_HOME=/opt/java8
ENV JAVA11_HOME=/opt/java11
ENV JAVA17_HOME=/opt/java17

# Verzeichnisse für die verschiedenen Java-Versionen erstellen
RUN mkdir -p $JAVA8_HOME $JAVA11_HOME $JAVA17_HOME

# Java 8 kopieren
COPY --from=java8 /usr/local/openjdk-8 $JAVA8_HOME

# Java 11 kopieren
COPY --from=java11 /usr/local/openjdk-11 $JAVA11_HOME

# Java 17 kopieren
COPY --from=java17 /usr/local/openjdk-17 $JAVA17_HOME

# Standard-Java-Version setzen (z. B. Java 11)
ENV JAVA_HOME=$JAVA11_HOME
ENV PATH=$JAVA_HOME/bin:$PATH

# Arbeitsverzeichnis festlegen
WORKDIR /home/container

# Startskript kopieren
COPY start.sh .

# Startskript ausführbar machen
RUN chmod +x start.sh

# Startbefehl
ENTRYPOINT ["./start.sh"]
