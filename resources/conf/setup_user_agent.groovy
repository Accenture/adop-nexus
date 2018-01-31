import groovy.json.JsonSlurper

parsed_args = new JsonSlurper().parseText(args)

core.userAgentCustomization(parsed_args.user_agent)
