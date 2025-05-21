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

# Créer le fichier application.properties
RUN mkdir -p src/main/resources && \
    echo "db.default.driver=org.postgresql.Driver" > src/main/resources/application.properties && \
    echo "db.default.url=jdbc:postgresql://${DB_HOST}:${DB_PORT}/${DB_NAME}" >> src/main/resources/application.properties && \
    echo "db.default.user=${DB_USER}" >> src/main/resources/application.properties && \
    echo "db.default.password=${DB_PASSWORD}" >> src/main/resources/application.properties && \
    echo "application.mode=prod" >> src/main/resources/application.properties && \
    echo "application.base-url=https://${RAILWAY_STATIC_URL}" >> src/main/resources/application.properties

# Compiler le WAR
RUN ./gradlew --no-daemon clean war -x test

# Liste des fichiers générés pour vérification
RUN ls -la build/libs/

# Télécharger et configurer Tomcat
RUN wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.85/bin/apache-tomcat-9.0.85.tar.gz && \
    tar -xzf apache-tomcat-9.0.85.tar.gz && \
    mv apache-tomcat-9.0.85 /opt/tomcat && \
    rm -rf /opt/tomcat/webapps/* && \
    mkdir -p /opt/tomcat/conf/Catalina/localhost

# Copier le fichier WAR et s'assurer qu'il est déployé comme ROOT
RUN cp build/libs/*.war /opt/tomcat/webapps/ROOT.war && \
    echo '<Context path="" docBase="${catalina.home}/webapps/ROOT.war"></Context>' > /opt/tomcat/conf/Catalina/localhost/ROOT.xml

# Définir JAVA_OPTS pour Tomcat
ENV JAVA_OPTS="-Xms512m -Xmx1024m -Daxelor.config=/opt/tomcat/conf/application.properties"

# Copier application.properties dans le répertoire conf de Tomcat
RUN cp src/main/resources/application.properties /opt/tomcat/conf/application.properties

# Exposer le port
EXPOSE 8080

# Lancer Tomcat avec les options configurées
CMD ["/opt/tomcat/bin/catalina.sh", "run"] 