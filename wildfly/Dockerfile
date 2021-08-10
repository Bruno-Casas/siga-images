FROM alpine:3.13

# Set the WILDFLY_VERSION env variable
ARG WILDFLY_VERSION=15.0.1.Final
ARG WILDFLY_SHA1=23d6a5889b76702fc518600fc5b2d80d6b3b7bb1
ENV WILDFLY_HOME=/opt/jboss/wildfly
ENV PATH="${WILDFLY_HOME}/bin:$PATH"

USER root

RUN apk add --no-cache curl bash openjdk8-jre

COPY install.sh /tmp
RUN /tmp/install.sh

ENV LAUNCH_JBOSS_IN_BACKGROUND=true

USER jboss

EXPOSE 8080

CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]