FROM eclipse-temurin:17-jdk

# Installer les outils
RUN apt-get update && apt-get install -y git wget unzip curl

WORKDIR /app

# Cloner le repo officiel webapp avec tous les modules
RUN git clone https://github.com/axelor/open-suite-webapp.git . && \
    git submodule init && \
    git submodule update && \
    git submodule foreach git checkout master && \
    git submodule foreach git pull origin master

# Compiler le .war
RUN ./gradlew --no-daemon clean war -x test

# Télécharger Tomcat
RUN wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz && \
    tar -xzf apache-tomcat-9.0.85.tar.gz && \
    mv apache-tomcat-9.0.85 /opt/tomcat && \
    rm -rf /opt/tomcat/webapps/*

# Déployer le .war généré
RUN cp build/libs/*.war /opt/tomcat/webapps/ROOT.war

# Générer le fichier application.properties
RUN echo "db.default.driver=org.postgresql.Driver" > /opt/tomcat/conf/application.properties && \
    echo "db.default.url=jdbc:postgresql://\${DB_HOST}:\${DB_PORT}/\${DB_NAME}" >> /opt/tomcat/conf/application.properties && \
    echo "db.default.user=\${DB_USER}" >> /opt/tomcat/conf/application.properties && \
    echo "db.default.password=\${DB_PASSWORD}" >> /opt/tomcat/conf/application.properties && \
    echo "application.base-url=https://\${RAILWAY_STATIC_URL}" >> /opt/tomcat/conf/application.properties

EXPOSE 8080
CMD ["/opt/tomcat/bin/catalina.sh", "run"]
