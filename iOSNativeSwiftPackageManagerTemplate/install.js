#!/usr/bin/env node

const fs = require('fs')
const path = require('path')

function replaceTextInFile(fileName, textInFile, replacementText) {
    const contents = fs.readFileSync(fileName, 'utf8')
    const result = contents.replace(textInFile, replacementText)
    fs.writeFileSync(fileName, result, 'utf8')
}


function getSwiftPackageRepoAndBranch() {
    const packageJson = require('./package.json')
    const spmRepoUrlWithBranch = packageJson.sdkDependencies["SalesforceMobileSDK-iOS-SPM"]
    const parts = spmRepoUrlWithBranch.split('#'), repoUrl = parts[0], branchOrTag = parts.length > 1 ? parts[1] : 'master'
    return {repoUrl: repoUrl, branchOrTag: branchOrTag}
}

function fixProjectFile(repoUrl, kind, key, value) {
    const projectDirName = fs.readdirSync('.').filter(f => f.endsWith('xcodeproj'))[0] // project name changes once template.js runs
    const projectFilePath = `./${projectDirName}/project.pbxproj`
    replaceTextInFile(projectFilePath,
		      /repositoryURL = ".*SalesforceMobileSDK-iOS-SPM";\s*requirement = {[^}]*};/m,
		      `repositoryURL = "${repoUrl}";\n\t\t\trequirement = {\n\t\t\t\tkind = ${kind};\n\t\t\t\t${key} = ${value};\n\t\t\t};`)
}

const spm = getSwiftPackageRepoAndBranch()
console.log(`Using Swift Package ${spm.repoUrl} at ${spm.branchOrTag}`)
if (isNaN(parseInt(spm.branchOrTag))) {
    fixProjectFile(spm.repoUrl, 'branch', 'branch', spm.branchOrTag)
} else {
    fixProjectFile(spm.repoUrl, 'exactVersion', 'version', spm.branchOrTag)
}
