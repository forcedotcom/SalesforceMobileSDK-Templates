#!/usr/bin/env node

var packageJson = require('./package.json')
var execSync = require('child_process').execSync;
var path = require('path');
var fs = require('fs');

console.log('Installing sdk dependencies');
for (var sdkDependency in packageJson.sdkDependencies) {
    var repoUrlWithBranch = packageJson.sdkDependencies[sdkDependency];
    var parts = repoUrlWithBranch.split('#'), repoUrl = parts[0], branch = parts.length > 1 ? parts[1] : 'master';
    var targetDir = path.join('mobile_sdk', sdkDependency);
    if (fs.existsSync(targetDir))
        console.log(targetDir + ' already exists - if you want to refresh it, please remove it and re-run install.js');
    else
        execSync('git clone --branch ' + branch + ' --single-branch --depth 1 ' + repoUrl + ' ' + targetDir, {stdio:[0,1,2]});
}

console.log('Installing pod dependencies');
execSync('pod update', {stdio:[0,1,2]});
