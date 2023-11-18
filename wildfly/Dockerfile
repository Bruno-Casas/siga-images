FROM alpine:3.18

# Set the WILDFLY_VERSION env variable
ARG WILDFLY_VERSION=26.1.3.Final
ARG WILDFLY_SHA1=b9f52ba41df890e09bb141d72947d2510caf758c
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