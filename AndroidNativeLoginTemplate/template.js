/*
 * Copyright (c) 2017-present, salesforce.com, inc.
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
 * @return result map with
 *   workspace
 *   bootconfigFile
 */
function prepare(config, replaceInFiles, moveFile, removeFile) {

    var path = require('path');

    // Values in template
    var templateAppName = 'AndroidNativeLoginTemplate';
    var templatePackageName = 'com.salesforce.androidnativelogintemplate';

    // Key files
    var templatePackageJsonFile = 'package.json';
    var templateSettingsGradle = 'settings.gradle.kts';
    var templateBuildGradleFile = path.join('app', 'build.gradle.kts');
    var templateStringsXmlFile = path.join('app', 'src', 'main', 'res', 'values', 'strings.xml');
    var templateBootconfigFile = path.join('app', 'src', 'main', 'res', 'values', 'bootconfig.xml');
    var templateMainActivityFile = path.join('app', 'src', 'main', 'java', 'com', 'salesforce', 'androidnativelogintemplate', 'MainActivity.kt');
    var templateMainApplicationFile = path.join('app', 'src', 'main', 'java', 'com', 'salesforce', 'androidnativelogintemplate', 'MainApplication.kt');
    var templateNativeLoginFile = path.join('app', 'src', 'main', 'java', 'com', 'salesforce', 'androidnativelogintemplate', 'NativeLogin.kt');
    var templateNativeLoginViewModelFile = path.join('app', 'src', 'main', 'java', 'com', 'salesforce', 'androidnativelogintemplate', 'NativeLoginViewModel.kt');

    //
    // Replace in files
    //

    // app name
    replaceInFiles(templateAppName, config.appname, [templatePackageJsonFile, templateSettingsGradle, templateStringsXmlFile]);

    // package name
    replaceInFiles(templatePackageName, config.packagename, [templateBuildGradleFile, templateStringsXmlFile, templateMainActivityFile, templateMainApplicationFile, templateNativeLoginFile, templateNativeLoginViewModelFile]);
    
    //
    // Rename/move files
    //
    var tmpPathActivityFile = path.join('app', 'src', 'MainActivity.kt');
    var tmpPathApplicationFile = path.join('app', 'src', 'MainApplication.kt');
    var tmpPathNativeLoginFile = path.join('app', 'src', 'NativeLogin.kt')
    var tmpPathNativeLoginViewModelFile = path.join('app', 'src', 'NativeLoginViewModel.kt')
    moveFile(templateMainActivityFile, tmpPathActivityFile);
    moveFile(templateMainApplicationFile, tmpPathApplicationFile);
    moveFile(templateNativeLoginFile, tmpPathNativeLoginFile);
    moveFile(templateNativeLoginViewModelFile, tmpPathNativeLoginViewModelFile);
    removeFile(path.join('app', 'src', 'main', 'java', 'com'));
    moveFile(tmpPathActivityFile, path.join.apply(null, ['app', 'src', 'main', 'java'].concat(config.packagename.split('.')).concat(['MainActivity.kt'])));
    moveFile(tmpPathApplicationFile, path.join.apply(null, ['app', 'src', 'main', 'java'].concat(config.packagename.split('.')).concat(['MainApplication.kt'])));
    moveFile(tmpPathNativeLoginFile, path.join.apply(null, ['app', 'src', 'main', 'java'].concat(config.packagename.split('.')).concat(['NativeLogin.kt'])));
    moveFile(tmpPathNativeLoginViewModelFile, path.join.apply(null, ['app', 'src', 'main', 'java'].concat(config.packagename.split('.')).concat(['NativeLoginViewModel.kt'])));

    //
    // Run install.js
    //
    require('./install');


    // Return paths of workspace and file with oauth config
    return {
        workspacePath: '',
        bootconfigFile: path.join('app', 'res', 'values', 'bootconfig.xml')
    };
}

//
// Exports
//
module.exports = {
    appType: 'native_kotlin',
    prepare: prepare
};

