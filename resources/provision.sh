#!/bin/bash

# A simple example script that publishes a number of scripts to the Nexus Repository Manager
# and executes them.

# fail if anything errors
set -e
# fail if a function call is missing an argument
set -u

username=admin
password=admin123

nexus_host=http://localhost:8081/${NEXUS_CONTEXT}

function addAndRunScript {
  name=$1
  file=$2
  args=${3:-false}
  echo $args
  groovy -Dgroovy.grape.report.downloads=true addUpdatescript.groovy -u "$username" -p "$password" -n "$name" -f "$file" -h "$nexus_host"
  printf "\nPublished $file as $name\n\n"
  curl -v -X POST -u $username:$password --header "Content-Type: text/plain" "$nexus_host/service/siesta/rest/v1/script/$name/run" -d $args
  printf "\nSuccessfully executed $name script\n\n\n"
}

printf "Provisioning Integration API Scripts Starting \n\n"
printf "Publishing and executing on $LDAP_URL\n"

LDAP_USER_GROUP_CONFIG="{\"name\":\"$LDAP_NAME\",\"map_groups_as_roles\":\"$LDAP_MAP_GROUP_AS_ROLES\",\"host\":\"$LDAP_URL\",\"port\":\"$LDAP_PORT\",\"searchBase\":\"$LDAP_SEARCH_BASE\",\"auth\":\"$LDAP_AUTH\",\"systemPassword\":\"$LDAP_AUTH_PASSWORD\",\"systemUsername\":\"$LDAP_AUTH_USERNAME\",\"emailAddressAttribute\":\"$LDAP_USER_EMAIL_ATTRIBUTE\",\"ldapGroupsAsRoles\":\"$LDAP_GROUPS_AS_ROLES\",\"groupBaseDn\":\"$LDAP_GROUP_BASE_DN\",\"groupIdAttribute\":\"$LDAP_GROUP_ID_ATTRIBUTE\",\"groupMemberAttribute\":\"$LDAP_GROUP_MEMBER_ATTRIBUTE\",\"groupMemberFormat\":\"$LDAP_GROUP_MEMBER_FORMAT\",\"groupObjectClass\":\"$LDAP_GROUP_OBJECT_CLASS\",\"userIdAttribute\":\"$LDAP_USER_ID_ATTRIBUTE\",\"userPasswordAttribute\":\"$LDAP_USER_PASSWORD_ATTRIBUTE\",\"userObjectClass\":\"$LDAP_USER_OBJECT_CLASS\",\"userBaseDn\":\"$LDAP_USER_BASE_DN\",\"userRealNameAttribute\":\"$LDAP_USER_REAL_NAME_ATTRIBUTE\"}"
NEXUS_DEVELOP_ROLE_CONFIG="{\"id\":\"developer\",\"name\":\"nx-developer\",\"description\":\"Developer_Role\",\"privileges\":"[\"nx-roles-update\",\"nx-ldap-update\"]",\"role\":"[]"}"
NEXUS_DEPLOY_ROLE_CONFIG="{\"id\":\"deployment\",\"name\":\"nx-deployment\",\"description\":\"Deployment_Role\",\"privileges\":"[\"nx-ldap-all\",\"nx-roles-all\"]",\"role\":"[]"}"
NEXUS_ADMIN_ROLE_CONFIG="{\"id\":\"admin\",\"name\":\"nx-admin\",\"description\":\"Adminstartion_Role\",\"privileges\":"[\"nx-all\"]",\"role\":"[]"}"



if [ "${LDAP_ENABLED}" = "true" ]
  then 
    addAndRunScript ldapConfig conf/ldapconfig.groovy $LDAP_USER_GROUP_CONFIG  
  if [[ "${NEXUS_CREATE_CUSTOM_ROLES}" = "true" ]];
   then
    echo "$(date) - Creating custom roles and mappings..."
    [[ -n "${NEXUS_CUSTOM_ADMIN_ROLE}" ]] && addAndRunScript InsertRole conf/insertrole.groovy $LDAP_ADMIN_ROLE_CONFIG
    [[ -n "${NEXUS_CUSTOM_DEPLOY_ROLE}" ]] && addAndRunScript InsertRole conf/insertrole.groovy $LDAP_DEPLOY_ROLE_CONFIG
    [[ -n "${NEXUS_CUSTOM_DEV_ROLE}" ]] && addAndRunScript InsertRole conf/insertrole.groovy $LDAP_DEVELOP_ROLE_CONFIG  
  fi
 fi
printf "\nProvisioning Scripts Completed\n\n"




