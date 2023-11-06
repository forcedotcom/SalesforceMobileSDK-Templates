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

    // Exclude tagged SalesforceMobileSDK-Android releases so it's only a source dependency pre-release.
    if (sdkDependency == 'SalesforceMobileSDK-Android' && branch.match(/v\d+\.\d+\.\d+/)) {
       if (fs.existsSync(targetDir)) {
           console.log('SalesforceMobileSDK-Android is a release version.  Warning: Its published artifacts will not be used since sources are already in ' + targetDir + ' and will be used.  If desired, remove this directory to return to the release artifacts.');
       } else {
           console.log('SalesforceMobileSDK-Android is a release version.  Skipping its source dependency and using published artifacts since it\'s only a source dependency for pre-release versions.');
       }
       continue;
    }

    if (fs.existsSync(targetDir))
        console.log(targetDir + ' already exists - if you want to refresh it, please remove it and re-run install.js');
    else
        execSync('git clone --branch ' + branch + ' --single-branch --depth 1 ' + repoUrl + ' ' + targetDir, {stdio:[0,1,2]});
}
