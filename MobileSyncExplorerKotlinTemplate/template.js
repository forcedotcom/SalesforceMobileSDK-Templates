/*
 * Copyright (c) 2022-present, salesforce.com, inc.
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

const path = require('path');
const fs = require('fs');

function listKtFiles(dirPath) {
    var result = [];
    fs.readdirSync(dirPath).forEach(function (file) {
        const fileFullPath = path.join(dirPath, file);
        const stats = fs.statSync(fileFullPath);
        if (fs.statSync(fileFullPath).isDirectory()) {
            result = result.concat(listKtFiles(fileFullPath));
        } else {
            if (file.endsWith('.kt')) {
                result.push(fileFullPath);
            }
        }
    });
    return result;
}


function prepare(config, replaceInFiles, moveFile, removeFile) {

    // Values in template
    const templateAppName = 'MobileSyncExplorerKotlinTemplate';
    const templatePackageName = 'com.salesforce.mobilesyncexplorerkotlintemplate';
    const templatePackagePath = templatePackageName.replace(/\./g, path.sep);
    const configPackagePath = config.packagename.replace(/\./g, path.sep);
    
    // Key files
    const templatePackageJsonFile = 'package.json';
    const templateSettingsGradle = 'settings.gradle.kts';
    const templateBuildGradleFile = path.join('app', 'build.gradle.kts');
    const templateStringsXmlFile = path.join('app', 'src', 'main', 'res', 'values', 'strings.xml');
    const templateBootconfigFile = path.join('app', 'src', 'main', 'res', 'values', 'bootconfig.xml');
    const javaDirPath = path.join('app', 'src', 'main', 'java');
    const ktFiles = listKtFiles(javaDirPath);

    //
    // Replace in files
    //

    // app name
    replaceInFiles(templateAppName, config.appname, [templatePackageJsonFile, templateSettingsGradle, templateStringsXmlFile]);

    // package name
    replaceInFiles(templatePackageName, config.packagename, [templateBuildGradleFile, templateStringsXmlFile].concat(ktFiles));

    //
    // Rename/move files
    //
    ktFiles.forEach(function(ktFilePath) {
        moveFile(ktFilePath, ktFilePath.replace(templatePackagePath, configPackagePath));
    })
    fs.rmdirSync(path.join(javaDirPath, templatePackagePath), {recursive: true});

    //
    // Run install.js
    //
    require('./install');


    // Return paths of workspace and file with oauth config
    return {
        workspacePath: '',
        bootconfigFile: path.join('app', 'src', 'main', 'res', 'values', 'bootconfig.xml')
    };
}

//
// Exports
//
module.exports = {
    appType: 'native_kotlin',
    prepare: prepare
};

