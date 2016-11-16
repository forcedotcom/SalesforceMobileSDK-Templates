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
 * @return result map with
 *   workspace
 *   bootconfigFile
 */
function prepare(config, replaceInFiles, moveFile, removeFile) {

    // Dependencies
    var path = require('path'),
        execSync = require('child_process').execSync;

    //
    // Install dependencies
    //
    console.log("cwd--->" + __dirname);
    execSync('npm install', {stdio:[0,1,2], cwd:__dirname});
    
    //
    // Move/remove some files
    //
    moveFile(path.join('node_modules', 'SalesforceMobileSDK-Shared', 'libs', 'force.js'), 'force.js');
    moveFile(path.join('node_modules', 'rachet', 'dist', 'css', 'ratchet.css'), 'rachet.css');
    moveFile(path.join('node_modules', 'rachet', 'dist', 'css', 'ratchet-theme-' + config.platform + '.min.css'), 'rachet-theme.css');
    removeFile('node_modules');
    removeFile('package.json');

    // Return paths of workspace and file with oauth config
    return {
        workspacePath: path.join('platforms', config.platform),
        bootconfigFile: path.join('www', 'bootconfig.json')
    };
}

//
// Exports
//
module.exports = {
    appType: 'hybrid_local',
    prepare: prepare
};
