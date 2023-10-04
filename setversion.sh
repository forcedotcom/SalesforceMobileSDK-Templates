#!/bin/bash

#set -x

OPT_VERSION=""
OPT_IS_DEV="no"
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

usage ()
{
    echo "Use this script to set Mobile SDK version number in source files"
    echo "Usage: $0 -v <version> [-d <isDev>]"
    echo "  where: version is the version e.g. 7.1.0"
    echo "         isDev is yes or no (default) to indicate whether it is a dev build"
}

parse_opts ()
{
    while getopts v:d: command_line_opt
    do
        case ${command_line_opt} in
            v)  OPT_VERSION=${OPTARG};;
            d)  OPT_IS_DEV=${OPTARG};;
        esac
    done

    if [ "${OPT_VERSION}" == "" ]
    then
        echo -e "${RED}You must specify a value for the version.${NC}"
        usage
        exit 1
    fi
}

# Helper functions
update_package_json ()
{
    local file=$1
    local version=$2
    gsed -i "s/\(SalesforceMobileSDK.*\)\#[^\"]*\"/\1\#${version}\"/g" ${file}
}

parse_opts "$@"

SDK_TAG=""
if [ "$OPT_IS_DEV" == "yes" ]
then
    SDK_TAG="dev"
else
    SDK_TAG="v${OPT_VERSION}"
fi

echo -e "${YELLOW}*** POINTING TO SDK TAG ${SDK_TAG} ***${NC}"

echo "*** Updating package.json files ***"

update_package_json "./AndroidIDPTemplate/package.json"  "${SDK_TAG}"
update_package_json "./AndroidNativeKotlinTemplate/package.json"  "${SDK_TAG}"
update_package_json "./AndroidNativeTemplate/package.json"  "${SDK_TAG}"
update_package_json "./HybridLocalTemplate/package.json"  "${SDK_TAG}"
update_package_json "./HybridRemoteTemplate/package.json"  "${SDK_TAG}"
update_package_json "./HybridLwcTemplate/package.json"  "${SDK_TAG}"
update_package_json "./MobileSyncExplorerKotlinTemplate/package.json"  "${SDK_TAG}"
update_package_json "./MobileSyncExplorerReactNative/package.json"  "${SDK_TAG}"
update_package_json "./MobileSyncExplorerSwift/package.json"  "${SDK_TAG}"
update_package_json "./ReactNativeTemplate/package.json"  "${SDK_TAG}"
update_package_json "./ReactNativeTypeScriptTemplate/package.json"  "${SDK_TAG}"
update_package_json "./ReactNativeDeferredTemplate/package.json"  "${SDK_TAG}"
update_package_json "./iOSIDPTemplate/package.json"  "${SDK_TAG}"
update_package_json "./iOSNativeSwiftEncryptedNotificationTemplate/package.json"  "${SDK_TAG}"
update_package_json "./iOSNativeSwiftTemplate/package.json"  "${SDK_TAG}"
update_package_json "./iOSNativeSwiftPackageManagerTemplate/package.json"  "${SDK_TAG}"
update_package_json "./iOSNativeTemplate/package.json"  "${SDK_TAG}"


