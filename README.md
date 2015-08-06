# Docker Nexus Repository

This is the Git repo for the Accenture DevOps Platform Nexus wrapper Docker file. It exposes a number of environment variable to enhance the configuration capabilities of the container.

# What is Nexus?

NexusÂ® is an artifact repository manager.

> [Sonatype/Nexus/Documentation](https://books.sonatype.com/nexus-book/reference/)

![logo](http://blog.sonatype.com/wp-content/uploads/2010/01/nexus-small.png)

# How to use this image?

## Run Nexus

To start the server, where version is the release version of the Docker container, run the following command.
    
      $ docker run -d --name nexus -p 8081:8081 -e ADOP_LDAP_ENABLED=false com.accenture.com/adop/nexus:VERSION

If LDAP authentication is disabled the default user/password is:
  
  * username: `admin`
  * password: `admin123`

## LDAP Authentication

By default, the image will enable LDAP authentication, setting the `ADOP_LDAP_ENABLED` environment variable to false will disable LDAP authentication. The variables write Nexus ldap.xml configuration file. 

The default nexus configuration depends on the following LDAP groups
  * nx-admin - administrators
  * nx-deployments - deployment users
  * nx-developers - developer accounts

Example run command:

      $ docker run -ti -p 8080:8081 -e LDAP_SEARCH_BASE=dc=adop,dc=accenture,dc=com -e ADOP_LDAP_ENABLED=true -e LDAP_URL=ldap.service.adop.consul -e LDAP_BIND_DN=cn= admin,dc=adop,dc=accenture,dc=com -e LDAP_USER_PASSWORD_ATTRIBUTE=userPassword -e    LDAP_USER_BASE_DN=ou=people -e LDAP_GROUP_BASE_DN=ou=groups -e LDAP_BIND_PASSWORD=password --dns=10.0.1.5 docker.accenture.com/adop/nexus:0.1.0

The image reads the following LDAP environment variables:

  * searchBase - `${LDAP_SEARCH_BASE}`
  * systemUsername - `${LDAP_BIND_DN}`
  * systemPassword - `${LDAP_BIND_PASSWORD}`
  * host - `${LDAP_URL}`
  * port - `${LDAP_PORT:-389}`
  * emailAddressAttribute - `${LDAP_USER_EMAIL_ATTRIBUTE:-mail}`
  * ldapGroupsAsRoles - `${LDAP_GROUPS_AS_ROLES:-true}`
  * groupBaseDn - `${LDAP_GROUP_BASE_DN}`
  * groupIdAttribute - `${LDAP_GROUP_ID_ATTRIBUTE:-cn}`
  * groupMemberAttribute - `${LDAP_GROUP_MEMBER_ATTRIBUTE-uniqueMember}`
  * groupMemberFormat - `${username}`
  * groupObjectClass - `${LDAP_GROUP_OBJECT_CLASS}`
  * preferredPasswordEncoding - `${LDAP_PREFERRED_PASSWORD_ENCODING:-crypt}`
  * userIdAttribute - `${LDAP_USER_ID_ATTRIBUTE:-uid}`
  * userObjectClass - `${LDAP_USER_OBJECT_CLASS:-inetOrgPerson}`
  * userBaseDn - `${LDAP_USER_BASE_DN}`
  * userRealNameAttribute - `${LDAP_USER_REAL_NAME_ATTRIBUTE:-cn}`

> [Sonatype/Nexus/plugin/LDAP/Documentation](https://books.sonatype.com/nexus-book/reference/ldap.html)

## Other configuration variables

 * `CONTEXT_PATH`, passed as -Dnexus-webapp-context-path. This is used to define the URL which Nexus is accessed.
 * `MAX_HEAP`, passed as -Xmx. Defaults to 1g.
 * `MIN_HEAP`, passed as -Xms. Defaults to 256m.
 * `JAVA_OPTS`. Additional options can be passed to the JVM via this variable. Default: -server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true.
 * `NEXUS_BASE_URL`, the nexus base URL
