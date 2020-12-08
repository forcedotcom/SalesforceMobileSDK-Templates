#!/usr/bin/env node

function replaceTextInFile(fileName, textInFile, replacementText) {
    var contents = fs.readFileSync(fileName, 'utf8');
    var lines = contents.split(/\r*\n/);
    var result = lines.map(function (line) {
        return line.replace(textInFile, replacementText);
    }).join('\n');

    fs.writeFileSync(fileName, result, 'utf8');
}

var packageJson = require('./package.json')
var execSync = require('child_process').execSync;
var path = require('path');
var fs = require('fs');

console.log('Installing npm dependencies');
execSync('yarn install', {stdio:[0,1,2]});

console.log('Installing sdk dependencies');
var sdkDependency = 'SalesforceMobileSDK-iOS';
var repoUrlWithBranch = packageJson.sdkDependencies[sdkDependency];
var parts = repoUrlWithBranch.split('#'), repoUrl = parts[0], branch = parts.length > 1 ? parts[1] : 'master';
var targetDir = path.join('mobile_sdk', sdkDependency);
if (fs.existsSync(targetDir)) {
    console.log(targetDir + ' already exists - if you want to refresh it, please remove it and re-run install.js');
} else {
    execSync('git clone --branch ' + branch + ' --single-branch --depth 1 ' + repoUrl + ' ' + targetDir, {stdio:[0,1,2]});
}

console.log('Installing pod dependencies');
// XXX remove following line once RNVectorIcons.podspec is fixed
replaceTextInFile('./node_modules/react-native-vector-icons/RNVectorIcons.podspec', "s.dependency 'React'", "s.dependency 'React-Core'")
execSync('pod update', {stdio:[0,1,2], cwd:'ios'});
