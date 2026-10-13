# Image d'exécution uniquement : le JAR est déjà construit et testé par la pipeline (étape 05)
# JRE et non JDK : on exécute Java, on ne compile pas → image plus légère
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY target/service_employe-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8081
ENTRYPOINT ["java", "-jar", "app.jar"]
