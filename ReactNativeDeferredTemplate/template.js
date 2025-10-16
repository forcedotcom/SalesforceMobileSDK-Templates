/*
 * Copyright (c) 2023-present, salesforce.com, inc.
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
 * Customize template (inject app name, package name, organization etc)
 *
 * @return list of maps with
 *   workspace
 *   bootconfigFile
 *   platform
 */
function prepare(config, replaceInFiles, moveFile, removeFile) {

    var platforms = config.platform.split(',');
    var result = [];

    if (platforms.indexOf('ios') >= 0) {

        var path = require('path');

        // Values in template
        var templateAppName = 'ReactNativeDeferredTemplate';
        var templatePackageName = 'com.salesforce.reactnativedeferredtemplate';
        var templateOrganization = 'ReactNativeDeferredTemplateOrganizationName';

        // Key files
        var templatePackageJsonFile = 'package.json';
        var templateIndexIosFile = 'index.js';
        var templatePodfile = path.join('ios', 'Podfile');
        var templateProjectDir = path.join('ios', templateAppName + '.xcodeproj');
        var templateProjectFile = path.join(templateProjectDir, 'project.pbxproj');
        var templateSchemeFile = path.join('ios', templateAppName + '.xcodeproj', 'xcshareddata', 'xcschemes', templateAppName + '.xcscheme');
        var templateEntitlementsFile = path.join('ios', templateAppName, templateAppName + '.entitlements');
        var templateAppDelegateFile = path.join('ios', templateAppName, 'AppDelegate.swift');
        var templateBootconfigFile = path.join('ios', templateAppName, 'bootconfig.plist');
        var templateInfoFile = path.join('ios', templateAppName, 'Info.plist');

        //
        // Replace in files
        //

        // app name
        replaceInFiles(templateAppName, config.appname, [templatePackageJsonFile, templateIndexIosFile, templatePodfile, templateProjectFile, templateSchemeFile, templateEntitlementsFile, templateAppDelegateFile]);

        // package name
        replaceInFiles(templatePackageName, config.packagename, [templateProjectFile, templateEntitlementsFile]);

        // org name
        replaceInFiles(templateOrganization, config.organization, [templateProjectFile]);

        // consumer key
        if (config.consumerkey && config.consumerkey !== '') {
            replaceInFiles('__INSERT_CONSUMER_KEY_HERE__', config.consumerkey, [templateBootconfigFile]);
        }

        // callback URL
        if (config.callbackurl && config.callbackurl !== '') {
            replaceInFiles('__INSERT_CALLBACK_URL_HERE__', config.callbackurl, [templateBootconfigFile]);
        }

        // login server
        var loginServer = (config.loginserver && config.loginserver !== '') ? config.loginserver.replace(/^https?:\/\//, '') : 'login.salesforce.com';
        replaceInFiles('__INSERT_DEFAULT_LOGIN_SERVER__', loginServer, [templateInfoFile]);

        //
        // Rename/move files
        //
        moveFile(templateSchemeFile, path.join('ios', templateAppName + '.xcodeproj', 'xcshareddata', 'xcschemes', config.appname + '.xcscheme'));
        moveFile(templateEntitlementsFile, path.join('ios', templateAppName, config.appname + '.entitlements'));
        moveFile(templateProjectDir, path.join('ios', config.appname + '.xcodeproj'));
        moveFile(path.join('ios', templateAppName), path.join('ios', config.appname));

        //
        // Run install.js
        //
        require('./installios');

        // Return paths of workspace and file with oauth config
        result.push({
            workspacePath: path.join('ios', config.appname + '.xcworkspace'),
            bootconfigFile: path.join('ios', config.appname, 'bootconfig.plist'),
            platform: 'ios'
        });
    }
    // Removing ios related files if ios is not targeted
    else {
        removeFile('ios');
        removeFile('installios.js');
    }


    if (platforms.indexOf('android') >= 0) {

        var path = require('path');

        // Values in template
        var templateAppName = 'ReactNativeDeferredTemplate';
        var templatePackageName = 'com.salesforce.reactnativedeferredtemplate';

        // Key files
        var templatePackageJsonFile = 'package.json';
        var templateIndexAndroidFile = 'index.js';
        var templateSettingsGradle = path.join('android', 'settings.gradle');
        var templateAndroidManifestFile = path.join('android', 'app', 'src', 'main', 'AndroidManifest.xml');
        var templateAppBuildGradleFile = path.join('android', 'app', 'build.gradle');
        var templateStringsXmlFile = path.join('android', 'app', 'src', 'main', 'res', 'values', 'strings.xml');
        var templateBootconfigFile = path.join('android', 'app', 'src', 'main', 'res', 'values', 'bootconfig.xml');
        var templateServersFile = path.join('android', 'app', 'src', 'main', 'res', 'xml', 'servers.xml');
        var templateMainActivityFile = path.join('android', 'app', 'src', 'main', 'java', 'com', 'salesforce', 'reactnativedeferredtemplate', 'MainActivity.kt');
        var templateMainApplicationFile = path.join('android', 'app', 'src', 'main', 'java', 'com', 'salesforce', 'reactnativedeferredtemplate', 'MainApplication.kt');

        //
        // Replace in files
        //

        // app name
        replaceInFiles(templateAppName, config.appname, [templatePackageJsonFile, templateIndexAndroidFile, templateSettingsGradle, templateStringsXmlFile, templateMainActivityFile]);

        // package name
        replaceInFiles(templatePackageName, config.packagename, [templateAndroidManifestFile, templateAppBuildGradleFile, templateStringsXmlFile, templateMainActivityFile, templateMainApplicationFile]);

        //
        // Rename/move/remove files
        //
        var tmpPathActivityFile = path.join('android', 'app', 'src', 'MainActivity.kt');
        var tmpPathApplicationFile = path.join('android', 'app', 'src', 'MainApplication.kt');
        moveFile(templateMainActivityFile, tmpPathActivityFile);
        moveFile(templateMainApplicationFile, tmpPathApplicationFile);
        removeFile(path.join('android', 'app', 'src', 'main', 'java'));
        var srcDirArr = ['android', 'app', 'src', 'main', 'java'].concat(config.packagename.split('.'));
        moveFile(tmpPathActivityFile, path.join.apply(null, srcDirArr.concat(['MainActivity.kt'])));
        moveFile(tmpPathApplicationFile, path.join.apply(null, srcDirArr.concat(['MainApplication.kt'])));

        // consumer key
        if (config.consumerkey && config.consumerkey !== '') {
            replaceInFiles('__INSERT_CONSUMER_KEY_HERE__', config.consumerkey, [templateBootconfigFile]);
        }

        // callback URL
        if (config.callbackurl && config.callbackurl !== '') {
            replaceInFiles('__INSERT_CALLBACK_URL_HERE__', config.callbackurl, [templateBootconfigFile]);
        }

        // login server
        var loginServer = (config.loginserver && config.loginserver !== '') ? config.loginserver : 'https://login.salesforce.com';
        replaceInFiles('__INSERT_DEFAULT_LOGIN_SERVER__', loginServer, [templateServersFile]);

        //
        // Run install.js
        //
        require('./installandroid');

        // Return paths of workspace and file with oauth config
        result.push({
            workspacePath: 'android',
            bootconfigFile: templateBootconfigFile,
            platform: 'android'
        });

    }
    // Removing android related files if ios is not targeted
    else {
        removeFile('android');
        removeFile('installandroid.js');
    }


    // Done
    return result;
}

//
// Exports
//
module.exports = {
    appType: 'react_native',
    prepare: prepare
};
