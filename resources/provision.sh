#!/bin/bash

# A simple example script that publishes a number of scripts to the Nexus Repository Manager
# and executes them.

# fail if anything errors
set -e

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

username=admin

if [ -f ${NEXUS_DATA}/admin.password ]; then
  password=$(<${NEXUS_DATA}/admin.password)
else
  echo "[ERR] File ${NEXUS_DATA}/admin.password doesn't exist. This file contain your current local password."
  exit 1
fi

function addAndRunScript() {
  name=$1
  file=$2
  eval args="${3:-false}"
  content=$(</$file)
  jq -n -c --arg name "$name" --arg content "$content" '{name: $name, content: $content, type: "groovy"}' | curl -v -X POST -u "${username}":"${password}" --header "Content-Type: application/json" "$nexus_host/service/rest/v1/script" -d@-
  printf "\nPublished $file as $name\n\n"
  curl -v -X POST -u "${username}":"${password}" --header "Content-Type: text/plain" "$nexus_host/service/rest/v1/script/$name/run" -d "$args"
  printf "\nSuccessfully executed $name script\n\n\n"
}

printf "Provisioning Integration API Scripts Starting \n\n"
printf "Publishing and executing on $nexus_host \n"

if [ -n "${NEXUS_BASE_URL}" ]
  then
  echo "$(date) - Base URL: ${NEXUS_BASE_URL}"
  # Add base url - requests timeout if incorrect
  baseUrlArg=$(jq -n -c --arg value "${NEXUS_BASE_URL}" '{base_url: $value}')
  addAndRunScript baseUrl resources/conf/setup_base_url.groovy "\$baseUrlArg"
fi

if [ -n "${USER_AGENT}" ]
  then
  echo "$(date) - User Agent: ${USER_AGENT}"
  userAgentArg=$(jq -n -c --arg value "${USER_AGENT}" '{user_agent: $value}')
  addAndRunScript userAgent resources/conf/setup_user_agent.groovy "\$userAgentArg"
fi

# Update Remote proxy configuration
if [[ -n "${NEXUS_PROXY_HOST}" ]] && [[ -n "${NEXUS_PROXY_PORT}" ]]
  then
  echo "$(date) - Proxy Host: ${NEXUS_PROXY_HOST}"
  echo "$(date) - Proxy Port: ${NEXUS_PROXY_PORT}"
  remoteProxyArg=$(jq -n -c --arg host "${NEXUS_PROXY_HOST}" --arg port "${NEXUS_PROXY_PORT}" '{with_http_proxy: "true", http_proxy_host: $host, http_proxy_port: $port}')
  addAndRunScript remoteProxy resources/conf/setup_http_proxy.groovy "\${remoteProxyArg}"
fi

if [ "${LDAP_ENABLED}" = "true" ]
  then
  echo "$(date) - Enabling LDAP"

  # LDAP parameters when LDAP is enabled
  LDAP_USER_GROUP_CONFIG=$( \
    jq -n -c \
    --arg name "${LDAP_NAME}" \
    --arg map_groups_as_roles "${LDAP_MAP_GROUP_AS_ROLES}" \
    --arg protocol "${LDAP_AUTH_PROTOCOL}" \
    --arg host "${LDAP_URL}" \
    --arg port "${LDAP_PORT}" \
    --arg searchBase "${LDAP_SEARCH_BASE}" \
    --arg auth "${LDAP_AUTH_SCHEME}" \
    --arg systemPassword "${LDAP_BIND_PASSWORD}" \
    --arg systemUsername "${LDAP_BIND_DN}" \
    --arg emailAddressAttribute "${LDAP_USER_EMAIL_ATTRIBUTE}" \
    --arg ldapGroupsAsRoles "${LDAP_GROUPS_AS_ROLES}" \
    --arg groupBaseDn "${LDAP_GROUP_BASE_DN}" \
    --arg groupIdAttribute "${LDAP_GROUP_ID_ATTRIBUTE}" \
    --arg groupMemberAttribute "${LDAP_GROUP_MEMBER_ATTRIBUTE}" \
    --arg groupMemberFormat "${LDAP_GROUP_MEMBER_FORMAT}" \
    --arg groupObjectClass "${LDAP_GROUP_OBJECT_CLASS}" \
    --arg userIdAttribute "${LDAP_USER_ID_ATTRIBUTE}" \
    --arg userPasswordAttribute "${LDAP_USER_PASSWORD_ATTRIBUTE}" \
    --arg userObjectClass "${LDAP_USER_OBJECT_CLASS}" \
    --arg userBaseDn "${LDAP_USER_BASE_DN}" \
    --arg userRealNameAttribute "${LDAP_USER_REAL_NAME_ATTRIBUTE}" \
    '{name: $name, map_groups_as_roles: $map_groups_as_roles, protocol: $protocol, host: $host, port: $port, searchBase: $searchBase, auth: $auth, systemPassword: $systemPassword, systemUsername: $systemUsername, emailAddressAttribute: $emailAddressAttribute, ldapGroupsAsRoles: $ldapGroupsAsRoles, groupBaseDn: $groupBaseDn, groupIdAttribute: $groupIdAttribute, groupMemberAttribute: $groupMemberAttribute, groupMemberFormat: $groupMemberFormat, groupObjectClass: $groupObjectClass, userIdAttribute: $userIdAttribute, userPasswordAttribute: $userPasswordAttribute, userObjectClass: $userObjectClass, userBaseDn: $userBaseDn, userRealNameAttribute: $userRealNameAttribute}' \
  )

  addAndRunScript ldapConfig resources/conf/ldapconfig.groovy "\${LDAP_USER_GROUP_CONFIG}"

  if [[ "${NEXUS_CREATE_CUSTOM_ROLES}" == "true" ]];
    then
    echo "$(date) - Creating custom roles and mappings..."
    if [ -n "${NEXUS_CUSTOM_DEPLOY_ROLE}" ]
      then
      NEXUS_DEPLOY_ROLE_CONFIG=$( \
        jq -n -c \
        --arg id "${NEXUS_CUSTOM_DEPLOY_ROLE}" \
        --arg name "${NEXUS_CUSTOM_DEPLOY_ROLE}" \
        '{id: $id, name: $name, description: "Deployment_Role", privileges: ["nx-ldap-all", "nx-roles-all"], roles: ["nx-admin"]}' \
      )
      addAndRunScript insertRole resources/conf/insertrole.groovy "\${NEXUS_DEPLOY_ROLE_CONFIG}"
    fi
    if [ -n "${NEXUS_CUSTOM_DEV_ROLE}" ]
      then
      NEXUS_DEVELOP_ROLE_CONFIG=$( \
        jq -n -c \
        --arg id "${NEXUS_CUSTOM_DEV_ROLE}" \
        --arg name "${NEXUS_CUSTOM_DEV_ROLE}" \
        '{id: $id, name: $name, description: "Developer_Role", privileges: ["nx-roles-update", "nx-ldap-update"], roles: ["nx-admin", "nx-anonymous"]}' \
      )
      addAndRunScript insertRole resources/conf/insertrole.groovy "\${NEXUS_DEVELOP_ROLE_CONFIG}"
    fi
    if [ -n "${NEXUS_CUSTOM_ADMIN_ROLE}" ]
      then
      NEXUS_ADMIN_ROLE_CONFIG=$( \
        jq -n -c \
        --arg id "${NEXUS_CUSTOM_ADMIN_ROLE}" \
        --arg name "${NEXUS_CUSTOM_ADMIN_ROLE}" \
        '{id: $id, name: $name, description: "Adminstration_Role", privileges: ["nx-all"], roles: ["nx-admin"]}' \
      )
      addAndRunScript insertRole resources/conf/insertrole.groovy "\${NEXUS_ADMIN_ROLE_CONFIG}"
    fi
  fi
fi

# Include Legacy URL 
File="${NEXUS_DATA}/etc/nexus.properties"
Property="org.sonatype.nexus.repository.httpbridge.internal.HttpBridgeModule.legacy=true"
cp ${NEXUS_DATA}/etc/nexus.properties ${NEXUS_DATA}/etc/nexus.properties_Backup
grep -qF "$Property" "$File" || echo "$Property" | tee --append "$File"

# Update the admin password if new password is set
if [ -n "${NEXUS_ADMIN_PASSWORD}" ]
  then
  NEXUS_PASSWORD=$( \
    jq -n -c \
    --arg value "${NEXUS_ADMIN_PASSWORD}" \
    '{new_password: $value}' \
  )
  addAndRunScript updatePassword resources/conf/update_admin_password.groovy "\${NEXUS_PASSWORD}"
  echo ${NEXUS_ADMIN_PASSWORD} > ${NEXUS_DATA}/admin.password
fi

printf "\nProvisioning Scripts Completed\n\n"
