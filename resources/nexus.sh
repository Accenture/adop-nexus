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

# Chown the nexus data directory
chown nexus:nexus "${NEXUS_DATA}"
chown -R nexus:nexus $(ls ${NEXUS_DATA} | awk -v NEXUS_DATA="${NEXUS_DATA}/" '{if($1 != "blobs"){ print NEXUS_DATA$1 }}')

# Dockerizing jmxpassword file
dockerize -template /resources/jmxremote.password.tmpl:/resources/jmxremote.password
chown -R nexus:nexus /resources && chmod 600 /resources/jmxremote.password

echo "Executing provision.sh"
nohup /usr/local/bin/provision.sh &

# Start nexus as the nexus user
su -c "${SONATYPE_DIR}/start-nexus-repository-manager.sh" -s /bin/sh nexus
