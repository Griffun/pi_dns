# lab.example.com
#
# This is an example dns file for lab.example.com.
# The uncommented portions are an example for how formatting should be done.
#
# Note that comments are ignored during generation. And so are blank lines.
#
# Also:
# If a record ends in a period, it will get a short AND a long-name
# i.e., the following line resolves for both 'server1' and 'server1.lab.example.com'
#
# 10.100.123.40 server1.
#
#
# Remember:
# - This is only for your private network.
# - Never expose your pihole to the internet.
# - Use as many sub-domains as you'd like.
# - DNS segmentation is not firewalling.
# - There are rarely wrong answers.
# - But this script supports two columns.
# - Adapt further to your other needs.
#


# Networking
10.11.12.1 router
10.11.12.2 switch

# Proxmox
10.11.12.8  bastion.
10.11.12.9  proxmox1.
10.11.12.10 proxmox2
10.11.12.11 proxmox3

# Primary cluster
10.11.12.20 mrmgr.
10.11.12.21 worker1
10.11.12.22 worker2
10.11.12.23 worker3

# Backup cluster
10.11.12.30 asstmgr.
10.11.12.31 workerb1
10.11.12.32 workerb2
10.11.12.33 workerb3

# Infra
10.11.12.53 pihole.

