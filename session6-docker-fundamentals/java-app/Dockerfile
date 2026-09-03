# Multi-stage build for minimal image size
FROM eclipse-temurin:17-jdk-alpine AS builder

WORKDIR /app
COPY App.java .
RUN javac App.java

FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/*.class ./

EXPOSE 8080

CMD ["java", "App"]
