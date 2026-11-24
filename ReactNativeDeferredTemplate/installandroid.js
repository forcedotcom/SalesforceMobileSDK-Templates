#!/usr/bin/env node

var packageJson = require('./package.json')
var execSync = require('child_process').execSync;
var path = require('path');
var fs = require('fs');

console.log('Installing npm dependencies');
require('./installnpm').install(__dirname);


console.log('Installing sdk dependencies');
var sdkDependency = 'SalesforceMobileSDK-Android';
var repoUrlWithBranch = packageJson.sdkDependencies[sdkDependency];
var parts = repoUrlWithBranch.split('#'), repoUrl = parts[0], branch = parts.length > 1 ? parts[1] : 'master';
var targetDir = path.join('mobile_sdk', sdkDependency);
if (fs.existsSync(targetDir)) {
    console.log(targetDir + ' already exists - if you want to refresh it, please remove it and re-run install.js');
} else {
    execSync('git clone --branch ' + branch + ' --single-branch --depth 1 ' + repoUrl + ' ' + targetDir, {stdio:[0,1,2]});
    fs.rmSync(path.join('mobile_sdk', 'SalesforceMobileSDK-Android', 'hybrid'), {recursive: true, force: true});
    fs.rmSync(path.join('mobile_sdk', 'SalesforceMobileSDK-Android', 'libs', 'test'), {recursive: true, force: true});

    // Patch settings.gradle.kts to exclude sample apps
    var settingsFile = path.join('mobile_sdk', 'SalesforceMobileSDK-Android', 'settings.gradle.kts');
    if (fs.existsSync(settingsFile)) {
        var settings = fs.readFileSync(settingsFile, 'utf8');
        // Comment out sample app includes
        settings = settings.replace(/^include\("(hybrid|native):/gm, '// include("$1:');
        fs.writeFileSync(settingsFile, settings, 'utf8');
        console.log('Patched settings.gradle.kts to exclude sample apps');
    }

}

