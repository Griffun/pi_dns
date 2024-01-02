# pi_dns
> Simple dns management in your homelab with nothing but git and pihole.

This is a simple set of scripts that will enable a basic configuration management and deployment pipeline for your lab dns. In my case, with gitea and one (or more) pihole instance.

This is not meant for production. Keep it in the homelab.


#### How I use it

This readme is a bit open ended for now, but here is how I am using this to help make my dns changes lightning fast, without ever leaving the terminal.

For the `main` branch, all files in the `domain.d` directory will be parsed and combined into a `custom.list` file, that is then pushed to [your pihole's](http://pi.hole/admin/dns_records.php) custom records config via git hook.

See the [included examples](domains.d/) to get an idea for how easy it can be.


###### TODO: 

 - [x] support for records in the top-level-domain
 - [ ] incorporate with a better githook management system - or make one
