#Supported tags and respective Dockerfile links

- [`0.2.0` (*0.2.0/Dockerfile*)](https://github.com/Accenture/adop-nexus/blob/master/Dockerfile.md)

# What is adop-nexus?
We have upgarded the nexus version to 3.7.1 and hence this image will enable the features of the latest version. To read more please cclick on the link -> https://books.sonatype.com/nexus-book/3.0/reference/ 

![logo](http://blog.sonatype.com/wp-content/uploads/2010/01/nexus-small.png)

# How to use this image?
We would recommend to make changes to the provision.sh script in order to add/delete anything as the docker restart would re-set everything as it is according to provision.sh

## Run Nexus

To start the server, where version is the release version of the Docker container, run the following command.
    
      $ docker run -d --name nexus -p 8081:8081 -e LDAP_ENABLED=false accenture/adop-nexus:VERSION

If LDAP authentication is disabled, the default user/password is:
  
  * username: `admin`
  * password: `admin123`
 
We should reset the default password by setting new password value with the configuration variable: `NEXUS_ADMIN_PASSWORD`=<New_Password>
## Persisting data

To persist data mount out the /nexus-data directory.

e.g. $ docker run -d --name nexus -v $(pwd)/data:/nexus-data -p 8081:8081 -e LDAP_ENABLED=false accenture/adop-nexus:VERSION

## LDAP Authentication

By default, the image will enable LDAP authentication, setting the `LDAP_ENABLED` environment variable to false will disable LDAP authentication. The variables write Nexus through API.

The default nexus configuration depends on the following LDAP groups
  * nx-admin - administrators
  * nx-deployments - deployment users
  * nx-developers - developer accounts

Example run command:

      $ docker run -ti -p 8080:8081 \
         -e LDAP_SEARCH_BASE=dc=example,dc=com \
         -e LDAP_ENABLED=true \
         -e LDAP_URL=ldap \
         -e LDAP_BIND_DN=cn=admin,dc=example,dc=com \
         -e LDAP_USER_PASSWORD_ATTRIBUTE=userPassword \
         -e LDAP_USER_BASE_DN=ou=people \ 
         -e LDAP_GROUP_BASE_DN=ou=groups \ 
         -e LDAP_BIND_PASSWORD=password \ 
         -e LDAP_NAME=nexusldap \
         -e LDAP_AUTH_SCHEME=simple \
         accenture/adop-nexus:VERSION

The image reads the following LDAP environment variables for ADOP OpenLDAP:

  * searchBase - `${LDAP_SEARCH_BASE}`
  * systemUsername - `${LDAP_BIND_DN}`
  * systemPassword - `${LDAP_BIND_PASSWORD}`
  * protocol - `${LDAP_AUTH_PROTOCOL}`
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

Additionally, the image reads the following LDAP environment variables if you want to use a Windows Active Directory:

  * groupIdAttribute - `${LDAP_GROUP_ID_ATTRIBUTE:-cn}`
  * groupMemberAttribute - `${LDAP_GROUP_MEMBER_ATTRIBUTE-uniqueMember}`
  * groupObjectClass - `${LDAP_GROUP_OBJECT_CLASS:-groups}`
  * userIdAttribute - `${LDAP_USER_ID_ATTRIBUTE:-sAMAccountName}`
  * userObjectClass - `${LDAP_USER_OBJECT_CLASS:-person}`
  * userBaseDn - `${LDAP_USER_BASE_DN}`
  * userRealNameAttribute - `${LDAP_USER_REAL_NAME_ATTRIBUTE:-cn}`

> [Sonatype/Nexus/plugin/LDAP/Documentation](https://books.sonatype.com/nexus-book/reference/ldap.html)

## Other configuration variables

 * `NEXUS_CONTEXT`, passed as -Dnexus-webapp-context-path. This is used to define the URL which Nexus is accessed.
 * `DEBUG_LOGGING`, defaults to false. If this is set to true, additional debug/access logs are enabled and sent to stdout/specified logging driver.
 * `MAX_HEAP`, passed as -Xmx. Defaults to 1g.
 * `MIN_HEAP`, passed as -Xms. Defaults to 256m.
 * `JAVA_OPTS`. Additional options can be passed to the JVM via this variable. Default: -server -XX:MaxPermSize=192m -Djava.net.preferIPv4Stack=true.
 * `NEXUS_BASE_URL`, the nexus base URL
 * `NEXUS_PROXY_HOST`, the proxy server that connects to Maven public repository. This is used if the Nexus Docker host has strict firewall implementation.
 * `NEXUS_PROXY_PORT`, the proxy server port.
 * `NEXUS_CENTRAL_REPO_URL`, if you want to change the Central Repo default maven public repository https://repo1.maven.org/maven2/
 * `NEXUS_CREATE_CUSTOM_ROLES`, if set to true, create custom roles according to the environment custom role variables:.
 * `NEXUS_CUSTOM_ADMIN_ROLE` , if set, create a custom group name with nx-admin role.
 * `NEXUS_CUSTOM_DEV_ROLE` , if set, create a custom group name with nx-developer role.
 * `NEXUS_CUSTOM_DEPLOY_ROLE`, if set, create a custom group name with nx-deployment role.
 * `USER_AGENT`, if set, you can enable Basic Authentication. [How do I enable WWW-Authenticate headers for content 401 responses]
 (https://support.sonatype.com/hc/en-us/articles/213465078-How-do-I-enable-WWW-Authenticate-headers-for-content-401-responses)
 
 
# License
Please view [licence information](LICENCE.md) for the software contained on this image.

#Supported Docker versions

This image is officially supported on Docker version 1.9.1.
Support for older versions (down to 1.6) is provided on a best-effort basis.

# User feedback

## Documentation
Documentation for this image is available in the [Sonatype/Nexus/Documentation](https://books.sonatype.com/nexus-book/reference/). 
Additional documentaion can be found under the [`docker-library/docs` GitHub repo](https://github.com/docker-library/docs). Be sure to familiarize yourself with the [repository's `README.md` file](https://github.com/docker-library/docs/blob/master/README.md) before attempting a pull request.

## Issues
If you have any problems with or questions about this image, please contact us through a [GitHub issue](https://github.com/Accenture/adop-nexus/issues).

## Contribute
You are invited to contribute new features, fixes, or updates, large or small; we are always thrilled to receive pull requests, and do our best to process them as fast as we can.

Before you start to code, we recommend discussing your plans through a [GitHub issue](https://github.com/Accenture/adop-nexus/issues), especially for more ambitious contributions. This gives other contributors a chance to point you in the right direction, give you feedback on your design, and help you find out if someone else is working on the same thing.
