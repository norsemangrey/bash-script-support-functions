#!/bin/bash

# Usage function.
usage() {
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -u, --url               URL of the Git repository to clone or update."
    echo "  -r, --root              Base directory where the repository will be cloned."
    echo "  -e, --executable        Name of the executable file to run within the repository."
    echo "  -d, --debug             Turns on detailed console output."
    echo "  -v, --verbose           Shows standards output from commands."
    echo "  -h, --help              Show this help message and exit."
    echo ""
}

# Preprocess long options first
while [[ $# -gt 0 ]]; do
    case "$1" in
        -u|--url)
            repositoryUrl=$2
            shift 2
            ;;
        -r|--root)
            baseDirectory=$2
            shift 2
            ;;
        -e|--executable)
            executableFile=$2
            shift 2
            ;;
        -d|--debug)
            debug=true
            shift
            ;;
        -v|--verbose)
            verbose=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Invalid option: $1" >&2
            usage
            exit 1
            ;;
    esac
done

# Ensure all required arguments are provided
if [[ -z "${repositoryUrl}" || -z "${baseDirectory}" || -z "${executableFile}" ]]; then

    # Run the usage function
    usage

fi

# Set external logger- and error handling script paths
# Getting absolute path as script might be called from another script
externalLogger=$(dirname "${BASH_SOURCE[0]}")"/logging-and-output-function.sh"
externalErrorHandler=$(dirname "${BASH_SOURCE[0]}")"/error-handling-function.sh"

# Source external logger and error handler (but allow execution without them)
source "${externalErrorHandler}" "Cloning and executing external repo failed" || true
source "${externalLogger}" || true

# Redirect output functions if not debug enabled
run() {

    if [[ "${verbose}" == "true" ]]; then

        "$@"

    else

        "$@" > /dev/null

    fi

}

# Extract the repository name from the URL
repoName=$(basename -s .git "${repositoryUrl}")
repoDirectory="${baseDirectory}/${repoName}"

# Check if the repository already exists
if [[ ! -d "${repoDirectory}" ]]; then

    logMessage "Cloning the repository (${repositoryUrl})..." "INFO"

    # Clone the repository along with all submodules
    run git clone --recurse-submodules "${repositoryUrl}" "${repoDirectory}"

    if [[ $? -ne 0 ]]; then

        logMessage "Failed to clone the repository." "ERROR"

        exit 1

    fi

    logMessage "Successfully cloned the repository." "INFO"

else

    logMessage "The repository already exists locally. Attempting to update..." "DEBUG"

    # Pull the latest changes
    run git -C "${repoDirectory}" pull

    # Update submodules to their correct versions
    run git -C "${repoDirectory}" submodule update --init --recursive

    if [[ $? -ne 0 ]]; then

        logMessage "Failed to update the repository." "WARNING"

    fi

    logMessage "Successfully updated the repository." "INFO"

fi

# Set executable file path
executableFile="${repoDirectory}/${executableFile}"

# Ensure the executable file is present and executable
if [[ -f "${executableFile}" ]]; then

    logMessage "Setting execute permissions on the script file (${executableFile})..." "DEBUG"

    # Set permissions on the script to execute
    chmod +x "${executableFile}"

    logMessage "Executing the script (${executableFile})..." "INFO"

    # Execute the script
    "${executableFile}"

    if [[ $? -eq 0 ]]; then

        logMessage "Script executed successfully." "INFO"

    else

        logMessage "Script execution failed." "WARNING"

    fi

else

    logMessage "Script file (${executableFile}) not found in the repository." "ERROR"

    exit 1

fi

exit 0
