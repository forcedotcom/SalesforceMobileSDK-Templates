/*
 * Copyright (c) 2016-present, salesforce.com, inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided
 * that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice, this list of conditions and the
 * following disclaimer.
 *
 * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
 * the following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or
 * promote products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * This script is called from forceios to inject app name, company id, org name etc in the template
 */

module.exports.prepare = function(config, replaceInFiles, moveFile, runProcessThrowError) {

    var path = require('path');

    // Values in template
    var templateAppName = 'iOSNativeSwiftTemplate';
    var templateCompanyId = 'com.salesforce.iosnativetemplate';
    var templateOrganization = 'iOSNativeSwiftTemplateOrganizationName';
    var templateAppId = '3MVG9Iu66FKeHhINkB1l7xt7kR8czFcCTUhgoA8Ol2Ltf1eYHOU4SqQRSEitYFDUpqRWcoQ2.dBv_a1Dyu5xa';
    var templateCallbackUri = 'testsfdc =///mobilesdk/detect/oauth/done';

    // Key files
    var templatePodfile = 'Podfile';
    var templatePackageFile = 'package.json';
    var templateProjectDir = templateAppName + '.xcodeproj';
    var templateProjectFile = path.join(templateProjectDir, 'project.pbxproj');
    var templateSchemeFile = path.join(templateAppName + '.xcodeproj', 'xcshareddata', 'xcschemes', templateAppName + '.xcscheme');
    var templateBridgingHeaderFile = path.join(templateAppName, 'Bridging-Header.h');
    var templateInfoFile = path.join(templateAppName, 'Info.plist');
    var templateEntitlementsFile = path.join(templateAppName, 'App.entitlements');
    var templateAppDelegateFile = path.join(templateAppName, 'AppDelegate.swift');

    //
    // Replace in files
    //

    // app name
    replaceInFiles(templateAppName, config.appname, [templatePodfile, templatePackageFile, templateProjectFile, templateSchemeFile, templateEntitlementsFile, templateAppDelegateFile]);

    // company id
    replaceInFiles(templateCompanyId, config.companyid, [templateInfoFile, templateEntitlementsFile]);

    // org name
    replaceInFiles(templateOrganization, config.organization, [templateProjectFile]);

    // app id
    if (config.appid) {
        replaceInFiles(templateAppId, config.appid, [templateAppDelegateFile]);
    }
                   
    // callback uri
    if (config.callbackuri) {
        replaceInFiles(templateCallbackUri, config.callbackuri, [templateAppDelegateFile]);
    }

    //
    // Rename files
    //
    moveFile(templateSchemeFile, path.join(templateAppName + '.xcodeproj', 'xcshareddata', 'xcschemes', config.appname + '.xcscheme'));
    moveFile(templateProjectDir, config.appname + '.xcodeproj');
    moveFile(templateAppName, config.appname);

    //
    // Run install.sh
    //
    runProcessThrowError('sh install.sh');

    // Return workspace relative path
    return config.appname + ".xcworkspace";

};
