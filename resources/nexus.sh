#! /bin/bash
set -e

echo "Starting Nexus."
echo "$(date) - LDAP Enabled: ${LDAP_ENABLED}"

# Copy config files.
mkdir -p ${NEXUS_HOME}/etc/logback

# Copy in custom logback configuration which prints application and access logs to stdout if environment variable is set to true
cp /resources/conf/logback/logback.xml ${NEXUS_HOME}/etc/logback/
if [[ ${DEBUG_LOGGING} == true ]]
  then
  cp /resources/conf/logback/logback-access.xml ${NEXUS_HOME}/etc/logback/
fi

# chown the nexus home directory
chown -R nexus:nexus ${NEXUS_HOME}

echo "Executing provision.sh"
nohup /usr/local/bin/provision.sh &
echo "$(date) - Base URL: ${NEXUS_BASE_URL}"

# start nexus as the nexus user
sh -c ${SONATYPE_DIR}/start-nexus-repository-manager.sh

