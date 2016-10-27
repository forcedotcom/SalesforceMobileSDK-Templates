#!/bin/bash

#
# Copyright (c) 2016-present, salesforce.com, inc. All rights reserved.
# 
# Redistribution and use of this software in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
# * Redistributions of source code must retain the above copyright notice, this list of conditions
# and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice, this list of
# conditions and the following disclaimer in the documentation and/or other materials provided
# with the distribution.
# * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
# endorse or promote products derived from this software without specific prior written
# permission of salesforce.com, inc.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
# FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
# WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

set -e
set -u
#set -x

#
# Script run by forceios to inject app name, org name etc in the template
# NB: this script does not validate arguments
#

# Command line option vars
OPT_APP_NAME=""
OPT_COMPANY_ID=""
OPT_ORG_NAME=""
OPT_APP_ID=""
OPT_REDIRECT_URI=""

# Template substitution keys
SUB_NATIVE_APP_NAME="iOSNativeSwiftTemplate"
SUB_COMPANY_ID="com.salesforce.iosnativeswifttemplate"
SUB_ORG_NAME="iOSNativeSwiftTemplateOrganizationName"
SUB_APP_ID="3MVG9Iu66FKeHhINkB1l7xt7kR8czFcCTUhgoA8Ol2Ltf1eYHOU4SqQRSEitYFDUpqRWcoQ2.dBv_a1Dyu5xa"
SUB_REDIRECT_URI="testsfdc:///mobilesdk/detect/oauth/done"

function parseOpts()
{
    while getopts :n:c:g:a:u: commandLineOpt; do
        case ${commandLineOpt} in
            n) OPT_APP_NAME=${OPTARG};;
            c) OPT_COMPANY_ID=${OPTARG};;
            g) OPT_ORG_NAME=${OPTARG};;
            a) OPT_APP_ID=${OPTARG};;
            u) OPT_REDIRECT_URI=${OPTARG};;
            ?)
            echo "Unknown option '-${OPTARG}'."
            exit 2;;
        esac
    done
}

function tokenSubstituteInFile()
{
    local subFile=$1
    local token=$2
    local replacement=$3

    if [[ -e "${subFile}" ]]; then
        echo ". Replacing ${token} by ${replacement} in ${subFile}"

        # Sanitize for sed
        token=`echo "${token}" | sed 's/[\&/]/\\\&/g'`
        replacement=`echo "${replacement}" | sed 's/[\&/]/\\\&/g'`
        
        cat "${subFile}" | sed "s/${token}/${replacement}/g" > "${subFile}.new"
        mv "${subFile}.new" "${subFile}"
    fi
}

function moveFile()
{
    local from=$1
    local to=$2
    echo ". Moving ${from} to ${to}"
    mv ${from} ${to}
}

function runPodInstall()
{
    echo ". Running pod install"
    pod install
}

function main()
{
    local appNameToken
    local inputAppDelegateFile
    local inputPodfile
    local inputPrefixFile
    local inputInfoFile
    local inputIndexiosFile
    local inputPackageJsonFile

    appNameToken=${SUB_NATIVE_APP_NAME}
    inputPodfile="Podfile"
    inputAppDelegateFile="${appNameToken}/AppDelegate.m"
    inputPrefixFile="${appNameToken}/Prefix.pch"
    inputInfoFile="${appNameToken}/Info.plist"
    inputProjectFile="${appNameToken}.xcodeproj/project.pbxproj"
    inputSharedSchemeFile="${appNameToken}.xcodeproj/xcshareddata/xcschemes/${appNameToken}.xcscheme"

    # App name
    tokenSubstituteInFile "${inputPodfile}" "${appNameToken}" "${OPT_APP_NAME}"
    tokenSubstituteInFile "${inputProjectFile}" "${appNameToken}" "${OPT_APP_NAME}"
    tokenSubstituteInFile "${inputSharedSchemeFile}" "${appNameToken}" "${OPT_APP_NAME}"
    tokenSubstituteInFile "${inputPrefixFile}" "${appNameToken}" "${OPT_APP_NAME}"
    tokenSubstituteInFile "${inputIndexiosFile}" "${appNameToken}" "${OPT_APP_NAME}"
    tokenSubstituteInFile "${inputAppDelegateFile}" "${appNameToken}" "${OPT_APP_NAME}"
    tokenSubstituteInFile "${inputPackageJsonFile}" "${appNameToken}" "${OPT_APP_NAME}"
    
    # Company identifier
    tokenSubstituteInFile "${inputInfoFile}" "${SUB_COMPANY_ID}" "${OPT_COMPANY_ID}"
    
    # Org name
    tokenSubstituteInFile "${inputProjectFile}" "${SUB_ORG_NAME}" "${OPT_ORG_NAME}"
    
    # Connected app ID
    tokenSubstituteInFile "${inputAppDelegateFile}" "${SUB_APP_ID}" "${OPT_APP_ID}"
    
    # Redirect URI
    tokenSubstituteInFile "${inputAppDelegateFile}" "${SUB_REDIRECT_URI}" "${OPT_REDIRECT_URI}"

    # Rename files, move to destination folder.
    moveFile "${inputSharedSchemeFile}" "${appNameToken}.xcodeproj/xcshareddata/xcschemes/${OPT_APP_NAME}.xcscheme"
    moveFile "${appNameToken}.xcodeproj" "${OPT_APP_NAME}.xcodeproj"
    moveFile "${appNameToken}" "${OPT_APP_NAME}"

    # Run pod install
    runPodInstall

    # Done
    echo "Successfully prepared app '${OPT_APP_NAME}'."
}

# Main
parseOpts "$@"
main

