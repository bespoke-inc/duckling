#!/usr/bin/env bash

# This script builds and pushes a docker image containing the code to run Facebook's Duckling.
#
# This script is intended to be run by our CI solution, pushing the "latest" tag.
# It can also be run by an administrator to allow using an alternate version of the code when automatically provisioning.
# In this case providing a tag (-t) will let the automation tool pull the alternate image.

set -euf -o pipefail

function print_help {
	usage="$(basename "${PROG_NAME}") [-p]...
	Build and push the docker image for this repository.
where:
    -h  show this help text
    -p  push the images to the private registry (default: no push)
    -g  run the script in debug mode, displaying as much information as possible (default: false)
    "
	echo "${usage}"
}

function param_error {
	echo "${1}" >&2
	print_help >&2
	exit 1
}

function build_image {
    if [ "${DEBUG}" = true ]; then
        QUIET_BUILD=""
    else
        QUIET_BUILD="-q"
    fi

    docker build ${QUIET_BUILD} -t "${BUILD_ID_IMG}" . > /dev/null
    echo "Image '${BUILD_ID_IMG}' built"
}

function push_images {
    echo "Pushing image '${BUILD_ID_IMG}'"
    docker push "${BUILD_ID_IMG}"
}

DEBUG=false
PUSH_IMAGES=false

PROG_NAME=${0}

set +u

while getopts "hpg" opt; do
    case $opt in
        h)
            print_help
            exit 0
            ;;
        p)
            PUSH_IMAGES=true
            ;;
        g)
            DEBUG=true
            ;;
        \?)
            param_error "Invalid option: -${OPTARG}."
            ;;
        :)
            param_error "Option -${OPTARG} requires an argument."
            ;;
    esac
done

shift $((OPTIND-1))

set -u

if [ "${DEBUG}" = true ]; then
    set -x
fi

TOPDIR=$(cd "$(dirname "$0")" && pwd)
IMG_NAME="bespokeinc/duckling"
BUILD_ID=$(git rev-parse HEAD)
BUILD_ID_IMG="${IMG_NAME}:${BUILD_ID}"

pushd "${TOPDIR}" 2>&1>/dev/null

build_image

if [ "${PUSH_IMAGES}" = true ]; then
    push_images
else
    echo "Skipping images pushing"
fi

popd 2>&1>/dev/null
