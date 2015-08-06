FROM sonatype/nexus:2.11.2-06

MAINTAINER Robert Northard, <robert.a.northard>

ENV ADOP_LDAP_ENABLED=true \
    NEXUS_HOME=/sonatype-work/

USER root

ADD resources/nexus.sh /usr/local/bin/
ADD resources/conf/ /${NEXUS_HOME}/conf/

RUN chmod +x /usr/local/bin/nexus.sh

ENTRYPOINT ["/usr/local/bin/nexus.sh"]
