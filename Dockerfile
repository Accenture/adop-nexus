FROM sonatype/nexus:2.11.2-06

MAINTAINER Robert Northard, <robert.a.northard>

ENV ADOP_LDAP_ENABLED=true \
    NEXUS_HOME=/sonatype-work/ \
    LDAP_SEARCH_BASE="" \
    LDAP_URL="" \
    LDAP_PORT=389 \
    LDAP_USER_EMAIL_ATTRIBUTE=mail \
    LDAP_GROUPS_AS_ROLES=true \
    LDAP_GROUP_BASE_DN=ou=groups
    LDAP_GROUP_ID_ATTRIBUTE=cn \
    LDAP_GROUP_MEMBER_ATTRIBUTE=uniqueMember \
    LDAP_GROUP_OBJECT_CLASS=groupOfUniqueNames \
    LDAP_PREFERRED_PASSWORD_ENCODING=crypt \
    LDAP_USER_ID_ATTRIBUTE=uid \
    LDAP_USER_PASSWORD_ATTRIBUTE=userPassword \
    LDAP_USER_OBJECT_CLASS=inetOrgPerson
    LDAP_USER_BASE_DN=ou-people \
    LDAP_USER_REAL_NAME_ATTRIBUTE=cn \
    LDAP_GROUP_MEMBER_FORMAT=dn

USER root

ADD resources/nexus.sh /usr/local/bin/
ADD resources/conf/ /resources

RUN chmod +x /usr/local/bin/nexus.sh

ENTRYPOINT ["/usr/local/bin/nexus.sh"]
