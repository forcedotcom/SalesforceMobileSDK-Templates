#!/bin/bash

#set -x

OPT_VERSION=""
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

usage ()
{
    echo "Use this script to set Mobile SDK version number in source files"
    echo "Usage: $0 -v <versionName e.g. 7.1.0> [-d <isDev e.g. yes>]"
}

parse_opts ()
{
    while getopts v: command_line_opt
    do
        case ${command_line_opt} in
            v)
                OPT_VERSION=${OPTARG};;
            ?)
                echo "Unknown option '-${OPTARG}'."
                usage
                exit 1;;
        esac
    done

    if [ "${OPT_VERSION}" == "" ]
    then
        echo "You must specify a value for the version."
        usage
        exit 1
    fi

    valid_version_regex='^[0-9]+\.[0-9]+\.[0-9]+$'
    if [[ "${OPT_VERSION}" =~ $valid_version_regex ]]
     then
         # No action
            :
     else
        echo "${OPT_VERSION} is not a valid version name.  Should be in the format <integer.integer.interger>"
        exit 2
    fi

}

# Helper functions
update_package_json ()
{
    local file=$1
    local version=$2
    sed -i "s/\.git\#[^\"]*\"/\.git\#v${version}\"/g" ${file}
}

parse_opts "$@"

echo -e "${YELLOW}*** SETTING VERSION TO ${OPT_VERSION}, IS DEV = ${OPT_IS_DEV} ***${NC}"

echo "*** Updating package.json files ***"
update_package_json "./AndroidNativeKotlinTemplate/package.json"  "${OPT_VERSION}"
update_package_json "./iOSIDPTemplate/package.json"  "${OPT_VERSION}"
update_package_json "./ReactNativeTemplate/package.json"  "${OPT_VERSION}"
update_package_json "./SmartSyncExplorerSwift/package.json"  "${OPT_VERSION}"
update_package_json "./HybridLocalTemplate/package.json"  "${OPT_VERSION}"
update_package_json "./AndroidNativeTemplate/package.json"  "${OPT_VERSION}"
update_package_json "./iOSNativeTemplate/package.json"  "${OPT_VERSION}"
update_package_json "./HybridRemoteTemplate/package.json"  "${OPT_VERSION}"
update_package_json "./AndroidIDPTemplate/package.json"  "${OPT_VERSION}"
update_package_json "./iOSNativeSwiftTemplate/package.json"  "${OPT_VERSION}"
update_package_json "./SmartSyncExplorerReactNative/package.json"  "${OPT_VERSION}"

