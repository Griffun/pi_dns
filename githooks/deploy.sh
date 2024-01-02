#!/usr/bin/env bash
# A simple git-hook script that will ssh into a docker host and
# run a dns update script for a particular pihole instance.
# (adjust as needed)
#
# Example install:
#
# - On gitea (running within docker), this will go somewhere like:
#    /data/git/repositories/chris/pi_dns.git/hooks/post-receive.d/
#
# - Or from the docker host:
#    /var/lib/docker/volumes/gitea/_data/git/repositories/user/pi_dns.git/hooks/post-receive.d/
#
# Configure these variables to work with your environment.
#   ...in mine, I have a user `deploy` on my docker vm that does the updating.
#
# ---
trigger_branch=main

ssh_opts="-o ConnectTimeout=5 -o PreferredAuthentications=publickey"
remote_user=deploy
remote_host=10.1.1.22 #docker2

git_path="/home/deploy/git/pi_dns/"
git_cmds="git checkout ${trigger_branch} && git pull"
post_pull_cmds="./gen_dns.sh"
# ---
#
# Customize this deploy function as needed
deploy() {
    echo
    log "Running: $0"
    log "  from node: $(whoami)@${host}"
    log "    and pushing to ${remote_user}@${remote_host}"
    echo
    log "Deploying branch: ${trigger_branch}"
    log "  to: ${remote_user}@${remote_host}:${git_path}"
    echo

    ssh ${ssh_opts} ${remote_user}@${remote_host}  \
        "cd ${git_path} && ${git_cmds} 2>&1 >/dev/null && ${post_pull_cmds}" \
            2> /dev/null || err_exit "Failed trying to ssh."

    echo
    log "Success"
    echo

    exit 0
}


log() { echo "  [$(date "+%Y-%m-%d %H:%M:%S")] :: ${*:-$(</dev/stdin)}" ; }
log_err() { >&2 log "ERROR: ${*:-$(</dev/stdin)}"; }
err_exit() { log_err "$*" ; echo ; exit 1 ; }

host=${HOSTNAME:-$(uname -n)}

while read oldrev newrev refname; do
    branch="$(git rev-parse --symbolic --abbrev-ref $refname)"
    if [ "${branch}" = "${trigger_branch}" ]; then
        deploy
    fi
done
