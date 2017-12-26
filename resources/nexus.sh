#! /bin/bash
set -e

echo "Starting Nexus."
echo "$(date) - LDAP Enabled: ${LDAP_ENABLED}"

# Copy config files.
mkdir -p ${NEXUS_HOME}/etc/logback

# chown the nexus home directory
chown -R nexus:nexus ${NEXUS_HOME}

# start nexus as the nexus user
sh -c ${SONATYPE_DIR}/start-nexus-repository-manager.sh

# Define the correct LDAP user and group mapping configurations
if [ -n "${NEXUS_BASE_URL}" ]
       then
       until $(curl --output /dev/null --silent --head --fail http://localhost:8081/${NEXUS_CONTEXT}); do
         sleep 10
       done
       # Add base url - requests timeout if incorrect
       nohup /usr/local/bin/provision.sh
       echo "$(date) - Base URL: ${NEXUS_BASE_URL}"
fi
