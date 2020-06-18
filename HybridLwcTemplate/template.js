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
    var path = require('path');

    // Values in template
    var templateOrganization = 'HybridLwcTemplateOrganization';

    // Key files
    var staticResourceDir = path.join('server', 'force-app', 'main', 'default', 'staticresources')
    var templateScratchDef = path.join('server', 'config', 'project-scratch-def.json');

    //
    // Install dependencies
    //
    require('./install');


    // Replace in files
    replaceInFiles(templateOrganization, config.organization, [templateScratchDef]);

    //
    // Move/remove some files
    //
    moveFile(path.join('mobile_sdk', 'SalesforceMobileSDK-Shared', 'libs', 'force.js'), path.join(staticResourceDir, 'other', 'force.js'));
    removeFile('node_modules');
    removeFile('mobile_sdk');
    removeFile('package.json');
    removeFile('template.js');
    removeFile('install.js');

    // Remove resource meta that do not apply
    ['ios', 'android'].forEach(function(os) {
        if (config.platform.split(',').indexOf(os) === -1) {
            removeFile(path.join(staticResourceDir, 'cordova' + os + '.resource-meta.xml'))
        }        
    });

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
    appType: 'hybrid_lwc',
    prepare: prepare
};

