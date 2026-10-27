#!/bin/bash
set -euo pipefail

sourceFile="${1:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/platform.sh}"
fakeKernel="linux"
fakeVendor="Generic"
fakeTarget="multi-user.target"
fakeSessions=""
unset WSL_DISTRO_NAME platform environment

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
usage() { printf 'caller usage\n'; }

grep() {
    local file="${@: -1}"
    local content
    case "${file}" in
        /proc/sys/kernel/osrelease) content="${fakeKernel}" ;;
        /sys/class/dmi/id/sys_vendor) content="${fakeVendor}" ;;
        *) fail "Unexpected grep input: ${file}" ;;
    esac
    command grep "${@:1:$#-1}" <<< "${content}"
}
timeout() {
    [[ "$*" == "5 systemctl get-default" ]] || fail "Unexpected timeout: $*"
    [[ -n "${fakeTarget}" ]] || return 1
    printf '%s\n' "${fakeTarget}"
}
ls() {
    [[ "$*" == "-A /usr/share/xsessions /usr/share/wayland-sessions" ]] ||
        fail "Unexpected ls: $*"
    printf '%s' "${fakeSessions}"
}

# Sourcing must ignore caller flags, preserve usage, and work under nounset/errexit.
set -- --caller-option
source "${sourceFile}"
[[ "${platform}" == physical && "${environment}" == headless ]] || fail "Initial detection"
[[ "$(usage)" == "caller usage" ]] || fail "Overwrote caller usage"

WSL_DISTRO_NAME=Ubuntu
[[ "$(detectPlatform)" == wsl ]] || fail "WSL environment"
unset WSL_DISTRO_NAME
fakeKernel="6.6-microsoft-standard-WSL2"
[[ "$(detectPlatform)" == wsl ]] || fail "WSL kernel"
fakeKernel=linux
fakeVendor="Microsoft Corporation"
[[ "$(detectPlatform)" == hyperv ]] || fail "Hyper-V"
fakeVendor=QEMU
[[ "$(detectPlatform)" == proxmox ]] || fail "Proxmox"
fakeVendor=Generic
[[ "$(detectPlatform)" == physical ]] || fail "Physical"

fakeSessions=plasma.desktop
[[ "$(detectEnvironment)" == headless ]] || fail "Non-graphical target"
fakeTarget=graphical.target
[[ "$(detectEnvironment)" == desktop ]] || fail "Installed desktop session"
fakeSessions=""
expected=headless
[[ ! -e /etc/systemd/system/display-manager.service ]] || expected=desktop
[[ "$(detectEnvironment)" == "${expected}" ]] || fail "Graphical target without sessions"
fakeTarget=""
[[ "$(detectEnvironment)" == headless ]] || fail "Unavailable systemd"

platform=proxmox
environment=desktop
source "${sourceFile}"
[[ "${platform}" == proxmox && "${environment}" == desktop ]] || fail "Explicit overrides"
platform=auto
environment=auto
source "${sourceFile}"
[[ "${platform}" == physical && "${environment}" == headless ]] || fail "Auto overrides"
platform=""
environment=""
source "${sourceFile}"
[[ "${platform}" == physical && "${environment}" == headless ]] || fail "Empty overrides"
[[ -z "$(source "${sourceFile}")" ]] || fail "Sourcing wrote output"

output=$(bash "${sourceFile}" --help)
[[ "${output}" == *"Usage:"* ]] || fail "Help"
if output=$(bash "${sourceFile}" --invalid 2>&1); then fail "Accepted invalid argument"; fi
[[ "${output}" == *"Invalid option:"* ]] || fail "Missing invalid argument diagnostic"
output=$(platform=proxmox environment=desktop bash "${sourceFile}")
[[ "${output}" == "Platform: 'proxmox'  -  Environment: 'desktop'." ]] || fail "Standalone output"

printf 'All platform tests passed: %s\n' "${sourceFile}"
