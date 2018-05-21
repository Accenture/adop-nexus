FROM sonatype/nexus3:3.7.1


ENV LDAP_ENABLED=true \
    NEXUS_CONTEXT=nexus \
    DEBUG_LOGGING=false \
    LDAP_SEARCH_BASE="" \
    LDAP_NAME=nexusldap \
    LDAP_URL="" \
    LDAP_PORT=389 \
    LDAP_AUTH_PROTOCOL=ldap \
    LDAP_AUTH_SCHEME=simple \
    LDAP_USER_EMAIL_ATTRIBUTE=mail \
    LDAP_GROUPS_AS_ROLES=true \
    LDAP_GROUP_BASE_DN=ou=groups \
    LDAP_GROUP_ID_ATTRIBUTE=cn \
    LDAP_GROUP_MEMBER_ATTRIBUTE=uniqueMember \
    LDAP_GROUP_OBJECT_CLASS=groupOfUniqueNames \
    LDAP_PREFERRED_PASSWORD_ENCODING=crypt \
    LDAP_MAP_GROUP_AS_ROLES=true \
    LDAP_USER_ID_ATTRIBUTE=uid \
    LDAP_USER_PASSWORD_ATTRIBUTE=userPassword \
    LDAP_USER_OBJECT_CLASS=inetOrgPerson \
    LDAP_USER_BASE_DN=ou=people \
    LDAP_USER_REAL_NAME_ATTRIBUTE=cn \
    LDAP_GROUP_MEMBER_FORMAT='${dn}' \
    NEXUS_CREATE_CUSTOM_ROLES=false

USER root

# Install groovy
RUN yum install -y zip unzip
RUN yum install -y which
RUN curl -s get.sdkman.io | bash
RUN source "$HOME/.sdkman/bin/sdkman-init.sh"
RUN yes | /bin/bash -l -c "sdk install groovy 2.4.15"

ENV PATH="/root/.sdkman/candidates/groovy/2.4.15/bin:${PATH}"
RUN export PATH

COPY resources/nexus.sh /usr/local/bin/
COPY resources/provision.sh /usr/local/bin/
COPY resources/ /resources/

RUN chmod u+x /usr/local/bin/nexus.sh && chmod u+x /usr/local/bin/provision.sh

ENTRYPOINT ["/usr/local/bin/nexus.sh"]
