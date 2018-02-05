import org.sonatype.nexus.ldap.persist.LdapConfigurationManager
import org.sonatype.nexus.ldap.persist.entity.LdapConfiguration
import org.sonatype.nexus.ldap.persist.entity.Connection
import org.sonatype.nexus.ldap.persist.entity.Mapping
import groovy.json.JsonSlurper

parsed_args = new JsonSlurper().parseText(args)


def ldapConfigMgr = container.lookup(LdapConfigurationManager.class.getName());

def ldapConfig = new LdapConfiguration()
boolean update = false;

// Look for existing config to update
ldapConfigMgr.listLdapServerConfigurations().each {
    if (it.name == parsed_args.name) {
        ldapConfig = it
        update = true
    }
}

ldapConfig.setName(parsed_args.name)

// Connection
connection = new Connection()
connection.setHost(new Connection.Host(Connection.Protocol.valueOf(parsed_args.protocol), parsed_args.host, Integer.valueOf(parsed_args.port)))
if (parsed_args.auth == "simple") {
    connection.setAuthScheme("simple")
    connection.setSystemUsername(parsed_args.systemUsername)
    connection.setSystemPassword(parsed_args.systemPassword)
} else {
    connection.setAuthScheme("none")
}
connection.setSearchBase(parsed_args.searchBase)
connection.setConnectionTimeout(30)
connection.setConnectionRetryDelay(300)
connection.setMaxIncidentsCount(3)
ldapConfig.setConnection(connection)


// Mapping
mapping = new Mapping()
mapping.setUserBaseDn(parsed_args.userBaseDn)
mapping.setUserObjectClass(parsed_args.userObjectClass)
mapping.setUserIdAttribute(parsed_args.userIdAttribute)
mapping.setUserRealNameAttribute(parsed_args.userRealNameAttribute)
mapping.setEmailAddressAttribute(parsed_args.emailAddressAttribute)

if (parsed_args.map_groups_as_roles) {
    mapping.setLdapGroupsAsRoles(true)
    mapping.setGroupBaseDn(parsed_args.groupBaseDn)
    mapping.setGroupObjectClass(parsed_args.groupObjectClass)
    mapping.setGroupIdAttribute(parsed_args.groupIdAttribute)
    mapping.setGroupMemberAttribute(parsed_args.groupMemberAttribute)
    mapping.setGroupMemberFormat(parsed_args.groupMemberFormat)
}


ldapConfig.setMapping(mapping)


if (update) {
    ldapConfigMgr.updateLdapServerConfiguration(ldapConfig)
} else {
    ldapConfigMgr.addLdapServerConfiguration(ldapConfig)
}
