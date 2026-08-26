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
 * Prepare template
 *
 * @return list of maps with
 *   workspace
 *   bootconfigFile
 *   platform
 */
function prepare(config, replaceInFiles, moveFile, removeFile) {

    // Dependencies
    var fs = require('fs');
    var path = require('path');

    //
    // Install dependencies
    //
    require('./install');

    // Key files
    var templateBootconfigFile = path.join('bootconfig.json');
    var templateServersFile = path.join('servers.xml'); // android only
    var templateInfoFile = path.join('..', 'platforms', 'ios', 'App', 'App-Info.plist'); // ios only

    //
    // Replace in files
    //

    // consumer key
    if (config.consumerkey && config.consumerkey !== '') {
        replaceInFiles('__INSERT_CONSUMER_KEY_HERE__', config.consumerkey, [templateBootconfigFile]);
    }

    // callback URL
    if (config.callbackurl && config.callbackurl !== '') {
        replaceInFiles('__INSERT_CALLBACK_URL_HERE__', config.callbackurl, [templateBootconfigFile]);
    }

    // login server for Android
    if (config.platform.includes('android')) {
        var loginServer = (config.loginserver && config.loginserver !== '') ? config.loginserver : 'https://login.salesforce.com';
        replaceInFiles('__INSERT_DEFAULT_LOGIN_SERVER__', loginServer, [templateServersFile]);
    }

    // login server for iOS
    if (config.platform.includes('ios')) {
        var loginServer = (config.loginserver && config.loginserver !== '') ? config.loginserver.replace(/^https?:\/\//, '') : 'login.salesforce.com';
        
        
        // Note: replaceInFiles processes line-by-line, so we need to do the replacement directly on the whole content
        var fileContent = fs.readFileSync(templateInfoFile, 'utf8');
        var searchPattern = /<plist version="1\.0">\s*<dict>\s*/;
        var replacePattern = '<plist version="1.0">\n<dict>\n\t<key>SFDCOAuthLoginHost</key>\n\t<string>' + loginServer + '</string>\n\t';
        var modifiedContent = fileContent.replace(searchPattern, replacePattern);
        fs.writeFileSync(templateInfoFile, modifiedContent, 'utf8');        
    }

    //
    // Move/remove some files
    //
    moveFile(path.join('mobile_sdk', 'SalesforceMobileSDK-Shared', 'libs', 'force.js'), 'force.js');
    if (config.platform.includes('android')) {
        var msdkAndroidPath = path.join('mobile_sdk', 'SalesforceMobileSDK-Android');
        // NB: template.js is running inside the web directory
        var msdkAndroidNewPath = path.join('..', 'platforms', 'android', 'mobile_sdk');
        var serversNewPath = path.join('..', 'platforms', 'android', 'app', 'src', 'main', 'res', 'xml', 'servers.xml');

        if (fs.existsSync(msdkAndroidPath)) {
            fs.mkdirSync(msdkAndroidNewPath);
            moveFile(msdkAndroidPath, msdkAndroidNewPath);
        }
        moveFile('servers.xml', serversNewPath);

        // Fill in the LoginActivity browser-redirect intent-filter. The CordovaPlugin post-install
        // hook injects the block with placeholder tokens; substitute the real callback values here
        // (like every other template type). If the block is missing (older plugin), inject it.
        // Host is empty for a hostless callback (never "*").
        if (config.callbackurl && config.callbackurl !== '' && config.callbackUrlScheme) {
            var manifestFile = path.join('..', 'platforms', 'android', 'app', 'src', 'main', 'AndroidManifest.xml');
            if (fs.existsSync(manifestFile)) {
                var manifestContent = fs.readFileSync(manifestFile, 'utf8');
                if (manifestContent.indexOf('com.salesforce.androidsdk.ui.LoginActivity') !== -1) {
                    // Substitute placeholders in the hook-injected block. The leading slash lives
                    // outside the path token; config.callbackUrlPath already carries its own.
                    replaceInFiles('__INSERT_CALLBACK_URL_SCHEME_HERE__', config.callbackUrlScheme, [manifestFile]);
                    replaceInFiles('__INSERT_CALLBACK_URL_HOST_HERE__', (config.callbackUrlHost || ''), [manifestFile]);
                    replaceInFiles('/__INSERT_CALLBACK_URL_PATH_HERE__', (config.callbackUrlPath || ''), [manifestFile]);
                } else {
                    // Fallback: block absent (older plugin). Inject it with real values.
                    var loginActivityBlock =
                        '        <!-- Salesforce Mobile SDK OAuth redirect (from --callbackurl). -->\n' +
                        '        <activity\n' +
                        '            android:name="com.salesforce.androidsdk.ui.LoginActivity"\n' +
                        '            android:exported="true"\n' +
                        '            android:launchMode="singleTask"\n' +
                        '            android:theme="@style/SalesforceSDK">\n' +
                        '            <intent-filter>\n' +
                        '                <action android:name="android.intent.action.VIEW" />\n' +
                        '                <category android:name="android.intent.category.DEFAULT" />\n' +
                        '                <category android:name="android.intent.category.BROWSABLE" />\n' +
                        '                <data\n' +
                        '                    android:scheme="' + config.callbackUrlScheme + '"\n' +
                        '                    android:host="' + (config.callbackUrlHost || '') + '"\n' +
                        '                    android:path="' + (config.callbackUrlPath || '') + '" />\n' +
                        '            </intent-filter>\n' +
                        '        </activity>\n';
                    manifestContent = manifestContent.replace(/([ \t]*)<\/application>/, loginActivityBlock + '$1</application>');
                    fs.writeFileSync(manifestFile, manifestContent, 'utf8');
                }
            }
        }
    }
    removeFile('node_modules');
    removeFile('mobile_sdk');
    removeFile('package.json');
    removeFile('template.js');
    removeFile('install.js');
    removeFile('servers.xml')

    // Return paths of workspace and file with oauth config
    return config.platform.split(',').map(platform => {
        return {
            workspacePath: path.join('platforms', platform),
            bootconfigFile: path.join('www', 'bootconfig.json'),
            platform: platform
        };
    });
}

//
// Exports
//
module.exports = {
    appType: 'hybrid_local',
    prepare: prepare
};
