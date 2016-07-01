#! /bin/bash
set -e

echo "Starting Nexus."
echo "$(date) - LDAP Enabled: ${LDAP_ENABLED}"

# Copy config files.
mkdir -p ${NEXUS_HOME}conf
cp -R /resources/* ${NEXUS_HOME}conf

# Delete lock file if instance was not shutdown cleanly.
if [ -e "${NEXUS_HOME}/nexus.lock" ] 
       then
       echo "$(date) Application was not shutdown cleanly, deleting lock file."
       rm -rf ${NEXUS_HOME}/nexus.lock
fi
 
if [ -n "${NEXUS_BASE_URL}" ]
       then
       # Add base url - requests timeout if incorrect
       sed -i "s#<baseUrl>.*#<baseUrl>${NEXUS_BASE_URL}</baseUrl>#" ${NEXUS_HOME}/conf/nexus.xml
       echo "$(date) - Base URL: ${NEXUS_BASE_URL}"
fi

# Update Remote proxy configuration
if [[ -n "${NEXUS_PROXY_HOST}" ]] && [[ -n "${NEXUS_PROXY_PORT}" ]]
    then
    echo "$(date) - Proxy Host: ${NEXUS_PROXY_HOST}"
    echo "$(date) - Proxy Port: ${NEXUS_PROXY_PORT}"
    REMOTE_PROXY_SETTINGS="<remoteProxySettings>\
    \n    <httpProxySettings>\
    \n      <proxyHostname>${NEXUS_PROXY_HOST}</proxyHostname>\
    \n      <proxyPort>${NEXUS_PROXY_PORT}</proxyPort>\
    \n    </httpProxySettings>\
    \n  </remoteProxySettings>"
   sed -i "s+<remoteProxySettings />+${REMOTE_PROXY_SETTINGS}+" ${NEXUS_HOME}/conf/nexus.xml
fi 

# Update Central Repo configuration
if [ ! -z "${NEXUS_CENTRAL_REPO_URL}" ]
        then
        echo "$(date) - Central Repository URL: ${NEXUS_CENTRAL_REPO_URL}"
        sed -i "s#https://repo1.maven.org/maven2/#${NEXUS_CENTRAL_REPO_URL}#" ${NEXUS_HOME}/conf/nexus.xml
fi

# Create a custom Nexus Roles
if [ ${NEXUS_CREATE_CUSTOM_ROLES} = true ]
         then
         echo "$(date) - Administrator role added: ${NEXUS_CUSTOM_ADMIN_ROLE}"
         echo "$(date) - Developer role added: ${NEXUS_CUSTOM_DEV_ROLE}"
         echo "$(date) - Deployment role added: ${NEXUS_CUSTOM_DEPLOY_ROLE}"
         INSERT_ROLE="<roles>\
         \n    <role>\
         \n      <id>${NEXUS_CUSTOM_ADMIN_ROLE}</id>\
         \n      <name>${NEXUS_CUSTOM_ADMIN_ROLE}</name>\
         \n      <roles>\
         \n        <role>nx-admin</role>\
         \n      </roles>\
         \n    </role>\
         \n    <role>\
         \n      <id>${NEXUS_CUSTOM_DEV_ROLE}</id>\
         \n      <name>${NEXUS_CUSTOM_DEV_ROLE}</name>\
         \n      <roles>\
         \n        <role>nx-developer</role>\
         \n      </roles>\
         \n    </role>\
         \n    <role>\
         \n      <id>${NEXUS_CUSTOM_DEPLOY_ROLE}</id>\
         \n      <name>${NEXUS_CUSTOM_DEPLOY_ROLE}</name>\
         \n      <roles>\
         \n        <role>nx-deployment</role>\
         \n      </roles>\
         \n    </role>\
         \n  </roles>"
         sed -i "s+</users>+</users>\n  ${INSERT_ROLE}+" ${NEXUS_HOME}/conf/security.xml
fi

if [ "${LDAP_ENABLED}" = true ]
  then
 
 # Delete default authentication realms (XMLauth..) from Nexus if LDAP auth is enabled
 # If you get locked out of nexus, restart nexus with LDAP_ENABLED=false.
 sed -i "/[a-zA-Z]*Xml*[a-zA-Z]/d"  ${NEXUS_HOME}/conf/security-configuration.xml

# Define the correct LDAP user and group mapping configurations
  LDAP_TYPE=${LDAP_TYPE:-openldap}
  echo "$(date) - LDAP Type: ${LDAP_TYPE}"
 
  case $LDAP_TYPE in
  'openldap')
   LDAP_USER_GROUP_CONFIG="  <userAndGroupConfig>
        <emailAddressAttribute>${LDAP_USER_EMAIL_ATTRIBUTE:-mail}</emailAddressAttribute>
        <ldapGroupsAsRoles>${LDAP_GROUPS_AS_ROLES:-true}</ldapGroupsAsRoles>
        <groupBaseDn>${LDAP_GROUP_BASE_DN}</groupBaseDn>
        <groupIdAttribute>${LDAP_GROUP_ID_ATTRIBUTE:-cn}</groupIdAttribute>
        <groupMemberAttribute>${LDAP_GROUP_MEMBER_ATTRIBUTE-uniqueMember}</groupMemberAttribute>
        <groupMemberFormat>\${${LDAP_GROUP_MEMBER_FORMAT:-dn}}</groupMemberFormat>
        <groupObjectClass>${LDAP_GROUP_OBJECT_CLASS:-groupOfUniqueNames}</groupObjectClass>
        <preferredPasswordEncoding>${LDAP_PREFERRED_PASSWORD_ENCODING:-crypt}</preferredPasswordEncoding>
        <userIdAttribute>${LDAP_USER_ID_ATTRIBUTE:-uid}</userIdAttribute>
        <userPasswordAttribute>${LDAP_USER_PASSWORD_ATTRIBUTE:-password}</userPasswordAttribute>
        <userObjectClass>${LDAP_USER_OBJECT_CLASS:-inetOrgPerson}</userObjectClass>
        <userBaseDn>${LDAP_USER_BASE_DN}</userBaseDn>
        <userRealNameAttribute>${LDAP_USER_REAL_NAME_ATTRIBUTE:-cn}</userRealNameAttribute>
      </userAndGroupConfig>"
  ;;

  'active_directory')
   LDAP_USER_GROUP_CONFIG="  <userAndGroupConfig>
        <emailAddressAttribute>mail</emailAddressAttribute>
        <ldapGroupsAsRoles>${LDAP_GROUPS_AS_ROLES:-true}</ldapGroupsAsRoles>
        <groupIdAttribute>${LDAP_GROUP_ID_ATTRIBUTE:-cn}</groupIdAttribute>
        <groupMemberAttribute>${LDAP_GROUP_MEMBER_ATTRIBUTE-uniqueMember}</groupMemberAttribute>
        <groupMemberFormat>\${${LDAP_GROUP_MEMBER_FORMAT:-dn}}</groupMemberFormat>
        <groupObjectClass>${LDAP_GROUP_OBJECT_CLASS:-groups}</groupObjectClass>
        <userIdAttribute>${LDAP_USER_ID_ATTRIBUTE:-sAMAccountName}</userIdAttribute>
        <userObjectClass>${LDAP_USER_OBJECT_CLASS:-person}</userObjectClass>
        <userBaseDn>${LDAP_USER_BASE_DN}</userBaseDn>
        <userRealNameAttribute>${LDAP_USER_REAL_NAME_ATTRIBUTE:-cn}</userRealNameAttribute>
        <userMemberOfAttribute>${LDAP_USER_MEMBER_ATTRIBUTE:-memberOf}</userMemberOfAttribute>
      </userAndGroupConfig>"
   ;;
  esac
 
cat > ${NEXUS_HOME}/conf/ldap.xml <<- EOM
<?xml version="1.0" encoding="UTF-8"?>
<ldapConfiguration>
  <version>2.8.0</version>
  <connectionInfo>
    <searchBase>${LDAP_SEARCH_BASE}</searchBase>
    <systemUsername>${LDAP_BIND_DN}</systemUsername>
    <systemPassword>${LDAP_BIND_PASSWORD}</systemPassword>
    <authScheme>simple</authScheme>
    <protocol>ldap</protocol>
    <host>${LDAP_URL}</host>
    <port>${LDAP_PORT:-389}</port>
  </connectionInfo>
${LDAP_USER_GROUP_CONFIG}
</ldapConfiguration>
EOM

else
    # Delete LDAP realm
    sed -i "/[a-zA-Z]*Ldap*[a-zA-Z]/d" ${NEXUS_HOME}/conf/security-configuration.xml
fi
 
# chown the nexus home directory
chown -R nexus:nexus ${NEXUS_HOME}
 
# start nexus as the nexus user
su -c "java \
-Dnexus-work=${SONATYPE_WORK} -Dnexus-webapp-context-path=${CONTEXT_PATH} \
-Xms${MIN_HEAP} -Xmx${MAX_HEAP} \
-cp 'conf/:lib/*' \
${JAVA_OPTS} \
org.sonatype.nexus.bootstrap.Launcher ${LAUNCHER_CONF}" -s /bin/bash nexus
