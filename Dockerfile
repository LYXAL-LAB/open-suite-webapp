FROM eclipse-temurin:11-jdk

WORKDIR /app

# Installer Git pour les sous-modules
RUN apt-get update && apt-get install -y git

# Cloner le dépôt
COPY . .

# Initialiser les sous-modules
RUN git submodule init && git submodule update

# Variables d'environnement pour la base de données
ENV AXELOR_DB_DRIVER org.postgresql.Driver
ENV AXELOR_DB_URL jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
ENV AXELOR_DB_USER ${DB_USER}
ENV AXELOR_DB_PASSWORD ${DB_PASSWORD}

# Compiler l'application (sans les tests)
RUN ./gradlew -x test build

# Exposer le port
EXPOSE 8080

# Démarrer l'application
CMD ["./gradlew", "run"] 