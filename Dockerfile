FROM eclipse-temurin:17-jdk

# Installer les outils nécessaires
RUN apt-get update && apt-get install -y git wget unzip curl

# Définir le dossier de travail
WORKDIR /app

# Cloner Axelor avec les sous-modules
RUN git clone --recurse-submodules https://github.com/axelor/axelor-open-suite.git .
RUN git submodule update --init --recursive

# Compiler en .war
RUN ./gradlew war -x test

# Télécharger Tomcat
RUN wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz && \
    tar -xzf apache-tomcat-9.0.85.tar.gz && \
    mv apache-tomcat-9.0.85 /opt/tomcat && \
    rm -rf /opt/tomcat/webapps/*

# Déployer le fichier WAR généré
RUN cp build/libs/*.war /opt/tomcat/webapps/ROOT.war

# Créer le fichier application.properties avec les variables d'environnement
RUN mkdir -p /opt/tomcat/conf/ && \
    echo "db.default.driver = org.postgresql.Driver" > /opt/tomcat/conf/application.properties && \
    echo "db.default.url = jdbc:postgresql://\${DB_HOST}:\${DB_PORT}/\${DB_NAME}" >> /opt/tomcat/conf/application.properties && \
    echo "db.default.user = \${DB_USER}" >> /opt/tomcat/conf/application.properties && \
    echo "db.default.password = \${DB_PASSWORD}" >> /opt/tomcat/conf/application.properties && \
    echo "application.mode = prod" >> /opt/tomcat/conf/application.properties && \
    echo "application.locale = fr" >> /opt/tomcat/conf/application.properties

# Exposer le port Railway
EXPOSE 8080

# Lancer Tomcat
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
