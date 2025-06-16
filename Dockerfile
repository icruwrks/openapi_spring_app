FROM public.ecr.aws/docker/library/amazoncorretto:17-alpine-jdk

RUN apk update && \
    apk add tzdata && \
    apk add curl

ENV TZ=Asia/Tokyo

EXPOSE 8080

ARG JAR_FILE=./spring-app/target/openapi-spring-1.0.11.jar
COPY ${JAR_FILE} .
ENTRYPOINT ["java", "-jar", "-Duser.language=ja", "-Duser.country=JP", "./openapi-spring-1.0.11.jar"]