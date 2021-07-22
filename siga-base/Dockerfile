FROM brunocasas/wildfly:15.0.1.Final-alpine

USER root
RUN apk add --no-cache inotify-tools
USER jboss

ENV SIGA_DIR "/opt/jboss/siga"
ENV PATH "${SIGA_DIR}/bin:$PATH"

WORKDIR /opt/jboss

COPY --chown=jboss:jboss resources/* siga/tmp/
RUN siga/tmp/configure.sh

COPY --chown=jboss:jboss siga/ siga/
RUN chmod -R +x siga/bin

CMD [ "jboss-eap-docker.sh" ]

EXPOSE 8080
EXPOSE 9990
