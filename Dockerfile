FROM eclipse-temurin:17-jdk

WORKDIR /app

# Installer les outils nécessaires
RUN apt-get update && apt-get install -y git wget unzip curl

# Copier le code source de ton repo déjà cloné par Railway
COPY . .

# Configurer Git pour éviter les erreurs SSH
RUN git config --global url."https://github.com/".insteadOf git@github.com: && \
    git config --global url."https://".insteadOf git:// && \
    git config --global --add safe.directory /app

# Init les submodules (dans le fork déjà cloné par Railway)
RUN git submodule init && \
    git submodule update && \
    git submodule foreach git checkout master || true && \
    git submodule foreach git pull origin master || true

# Configuration PostgreSQL
ENV AXELOR_DB_DRIVER org.postgresql.Driver
ENV AXELOR_DB_URL jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}
ENV AXELOR_DB_USER ${DB_USER}
ENV AXELOR_DB_PASSWORD ${DB_PASSWORD}

# Générer application.properties
RUN mkdir -p src/main/resources && \
    echo "db.default.driver = ${AXELOR_DB_DRIVER}" > src/main/resources/application.properties && \
    echo "db.default.url = ${AXELOR_DB_URL}" >> src/main/resources/application.properties && \
    echo "db.default.user = ${AXELOR_DB_USER}" >> src/main/resources/application.properties && \
    echo "db.default.password = ${AXELOR_DB_PASSWORD}" >> src/main/resources/application.properties && \
    echo "application.base-url=https://${RAILWAY_STATIC_URL}" >> src/main/resources/application.properties

# Compiler l'application (ignore les tests pour aller plus vite)
RUN ./gradlew -x test build

EXPOSE 8080

# Démarrer l'application (mode dev embarqué)
CMD ["./gradlew", "run"]
