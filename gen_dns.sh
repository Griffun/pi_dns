#!/usr/bin/env bash

# Set a hostname that we expect to match in order to run
EXPECTED_HOSTNAME="docker"

# Initial vars
SCRIPT_LOC="$(realpath "$0")"
SCRIPT_DIR="$(dirname "${SCRIPT_LOC}")"

IFS=$'\n'
cd "${SCRIPT_DIR}"
GIT_ROOT="$(git rev-parse --show-toplevel)"

log() { echo "[$(date "+%Y-%m-%d %H:%M:%S")] :: ${*:-$(</dev/stdin)}" ; }
log_err() { >&2 log "ERROR: ${*:-$(</dev/stdin)}"; }
err_exit() { log_err "$*" ; exit 1 ; }

host=${HOSTNAME:-$(uname -n)}
log "Running $0 on $host"

ensure() { command -v "$1" &> /dev/null \
    || err_exit "Required command $1 is missing. Exiting."; }

declare -a cmds

# Validate sudoers rules are in place
precheck() {
    log "Starting prechecks..."

    # Check that our hostname contains the expected...
    echo $host | egrep -qi "${EXPECTED_HOSTNAME}" \
        || err_exit "Failed to verify hostname matched ${EXPECTED_HOSTNAME}"

    # Bail if we cannot find our git dir
    [[ -z $GIT_ROOT ]] && err_exit "Could not determine git root dir. Exiting."

    # Ensure we have all the commands we need
    for i in realpath dirname git mktemp awk; do ensure $i; done

    # Check that we have the required sudoers rules configured
    run_commands --verify

    log "Prechecks complete."
}

run_commands() {
    if [[ -z "${cmds}" ]]; then
        cmds=($(grep NOPASSWD ${GIT_ROOT}/sudoers.d/* | awk -F"NOPASSWD: " '{print $2}'))

        [[ -z ${cmds} ]] \
            && err_exit "Failed to determine commands to run from sudoers file. Exiting."
    fi

    for cmd in "${cmds[@]}";do
        if [[ $1 == "--verify" ]]; then
            sudo -nl | grep -q "${cmd}" \
                || err_exit "Could not verify sudo for: $cmd. Exiting."
        else
            log "Running: $cmd"
            eval sudo ${cmd} \
                && log "Done." \
                || log_err "Failed when trying to run_commands."
        fi
    done
}

main() {
    # Setup our temporary/working dir
    tmp_dir=$(mktemp -d /tmp/pi_dns.XXXX)
    mkdir -p "${tmp_dir}" \
        && touch "${tmp_dir}/custom.list" \
          || err_exit "Failed working with tmp_dir. Exiting." \
          && log "Using tmp dir: ${host}:${tmp_dir}"

    # Combine all of our dns.d files
    for file in domains.d/*;do
        domain=${file##*/}
        dots=${domain//[^.]}

        if [[ ${#dots} -eq 0 ]];then
            log_err "$domain has no dots. Continuing..." && continue

        elif [[ ${#dots} -eq 1 ]];then # top level domain, via dnsmasq.d/custom.conf
            for record in $(grep -o '^[^#]*' ${file} | sort -V | sed 's/[[:blank:]]*$//' );do
                echo $record | \
                    awk -v domain="$domain" 'OFS="/" {print "address=" , $2"."domain , $1}'
            done >> "${tmp_dir}/custom.conf"

        else # subdomain, via pihole/custom.list
            for record in $(grep -o '^[^#]*' ${file} | sort -V | sed 's/[[:blank:]]*$//' );do
                # If the record ends in a period, put short and long names.
                if [[ "${record: -1}" == "." ]]; then
                    echo "${record}${domain}"
                    echo "${record:0:${#record}-1}"
                else
                    echo "${record}.${domain}"
                fi
            done >> "${tmp_dir}/custom.list"

        fi
    done

    cd ${tmp_dir} && run_commands

    echo
    log "Finished -- Check at: http://pi.hole/admin/dns_records.php"
}

# Deploy it
precheck
main
