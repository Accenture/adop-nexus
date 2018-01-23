#!/bin/bash

# A simple example script that publishes a number of scripts to the Nexus Repository Manager
# and executes them.

# fail if anything errors
set -e
# fail if a function call is missing an argument
#set -u

username=admin
password=admin123
nexus_host=http://localhost:8081/$NEXUS_CONTEXT
pretty_sleep() {
    secs=${1:-60}
    tool=${2:-service}
    while [ $secs -gt 0 ]; do
        echo -ne "$tool unavailable, sleeping for: $secs\033[0Ks\r"
        sleep 1
        : $((secs--))
    done
    echo "$tool was unavailable, so slept for: ${1:-60} secs"
}

echo "* Waiting for the Nexus3 to become available - this can take a few minutes"
TOOL_SLEEP_TIME=30
until [[ $(curl -I -s -u "${username}":"${password}" localhost:8081/${NEXUS_CONTEXT}/|head -n 1|cut -d$' ' -f2) == 200 ]]; do pretty_sleep ${TOOL_SLEEP_TIME} Nexus3; done

function addAndRunScript {
  name=$1
  file=$2
  args=${3:-false}
  groovy -Dgroovy.grape.report.downloads=true resources/conf/addUpdatescript.groovy -u "$username" -p "$password" -n "$name" -f "$file" -h "$nexus_host"
  printf "\nPublished $file as $name\n\n"
  curl -v -X POST -u $username:$password --header "Content-Type: text/plain" "$nexus_host/service/siesta/rest/v1/script/$name/run" -d $args
  printf "\nSuccessfully executed $name script\n\n\n"
}

printf "Provisioning Integration API Scripts Starting \n\n"
printf "Publishing and executing on $nexus_host \n"


if [ -n "${NEXUS_BASE_URL}" ]
  then
  # Add base url - requests timeout if incorrect
  baseUrlArg="{\"base_url\":\"${NEXUS_BASE_URL}\"}"
  addAndRunScript baseUrl resources/conf/setup_base_url.groovy $baseUrlArg
  echo "$(date) - Base URL: ${NEXUS_BASE_URL}"
fi

# Update Remote proxy configuration
if [[ -n "${NEXUS_PROXY_HOST}" ]] && [[ -n "${NEXUS_PROXY_PORT}" ]]
  then
  echo "$(date) - Proxy Host: ${NEXUS_PROXY_HOST}"
  echo "$(date) - Proxy Port: ${NEXUS_PROXY_PORT}"
  remoteProxyArg="{\"with_http_proxy\":\"true\",\"http_proxy_host\":\"${NEXUS_PROXY_HOST}\",\"http_proxy_port\":\"${NEXUS_PROXY_PORT}\"}"	
  addAndRunScript remoteProxy resources/conf/setup_http_proxy.groovy $remoteProxyArg
fi


#LDAP parameters when LDAP is enabled 
LDAP_USER_GROUP_CONFIG="{\"name\":\"$LDAP_NAME\",\"map_groups_as_roles\":\"$LDAP_MAP_GROUP_AS_ROLES\",\"host\":\"$LDAP_URL\",\"port\":\"$LDAP_PORT\",\"searchBase\":\"$LDAP_SEARCH_BASE\",\"auth\":\"$LDAP_AUTH\",\"systemPassword\":\"$LDAP_BIND_PASSWORD\",\"systemUsername\":\"$LDAP_BIND_DN\",\"emailAddressAttribute\":\"$LDAP_USER_EMAIL_ATTRIBUTE\",\"ldapGroupsAsRoles\":\"$LDAP_GROUPS_AS_ROLES\",\"groupBaseDn\":\"$LDAP_GROUP_BASE_DN\",\"groupIdAttribute\":\"$LDAP_GROUP_ID_ATTRIBUTE\",\"groupMemberAttribute\":\"$LDAP_GROUP_MEMBER_ATTRIBUTE\",\"groupMemberFormat\":\"$LDAP_GROUP_MEMBER_FORMAT\",\"groupObjectClass\":\"$LDAP_GROUP_OBJECT_CLASS\",\"userIdAttribute\":\"$LDAP_USER_ID_ATTRIBUTE\",\"userPasswordAttribute\":\"$LDAP_USER_PASSWORD_ATTRIBUTE\",\"userObjectClass\":\"$LDAP_USER_OBJECT_CLASS\",\"userBaseDn\":\"$LDAP_USER_BASE_DN\",\"userRealNameAttribute\":\"$LDAP_USER_REAL_NAME_ATTRIBUTE\"}"

if [ "${LDAP_ENABLED}" = "true" ]
  then 
    addAndRunScript ldapConfig resources/conf/ldapconfig.groovy $LDAP_USER_GROUP_CONFIG  
  if [[ "${NEXUS_CREATE_CUSTOM_ROLES}" == "true" ]];
   then
    echo "$(date) - Creating custom roles and mappings..."
    [[ -n "${NEXUS_CUSTOM_ADMIN_ROLE}" ]] 
    NEXUS_ADMIN_ROLE_CONFIG="{\"id\":\"$NEXUS_CUSTOM_ADMIN_ROLE\",\"name\":\"Admin\",\"description\":\"Adminstration_Role\",\"privileges\":\"nx-all\",\"role\":\"nx-admin\"}"
    addAndRunScript insertRole resources/conf/insertrole.groovy $NEXUS_ADMIN_ROLE_CONFIG
    [[ -n "${NEXUS_CUSTOM_DEPLOY_ROLE}" ]]
    NEXUS_DEPLOY_ROLE_CONFIG="{\"id\":\"$NEXUS_CUSTOM_DEPLOY_ROLE\",\"name\":\"Deployment\",\"description\":\"Deployment_Role\",\"privileges\":"[\"nx-ldap-all\",\"nx-roles-all\"]",\"role\":\"nx-admin\"}"
    addAndRunScript insertRole resources/conf/insertrole.groovy $NEXUS_DEPLOY_ROLE_CONFIG
    [[ -n "${NEXUS_CUSTOM_DEV_ROLE}" ]]
    NEXUS_DEVELOP_ROLE_CONFIG="{\"id\":\"$NEXUS_CUSTOM_DEV_ROLE\",\"name\":\"Developer\",\"description\":\"Developer_Role\",\"privileges\":"[\"nx-roles-update\",\"nx-ldap-update\"]",\"role\":"[\"nx-admin\",\"nx-anonymous\"]"}"
    addAndRunScript insertRole resources/conf/insertrole.groovy $NEXUS_DEVELOP_ROLE_CONFIG
  fi
 fi

#Include Legacy URL 
File="${NEXUS_HOME}/etc/nexus-default.properties"
Property="org.sonatype.nexus.repository.httpbridge.internal.HttpBridgeModule.legacy=true"
cp ${NEXUS_HOME}/etc/nexus-default.properties ${NEXUS_HOME}/etc/nexus-default.properties_Backup
grep -qF "$Property" "$File" || echo "$Property" | tee --append "$File"


#update the admin password if new password is set
if [ -n "${NEXUS_ADMIN_PASSWORD}" ]
  then
  NEXUS_PASSWORD="{\"new_password\":\"$NEXUS_ADMIN_PASSWORD\"}"
  addAndRunScript updatePassword resources/conf/update_admin_password.groovy $NEXUS_PASSWORD
fi


printf "\nProvisioning Scripts Completed\n\n"




