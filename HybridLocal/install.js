#!/usr/bin/env node

var execSync = require('child_process').execSync;
console.log('Installing npm dependencies');
execSync('npm install', {stdio:[0,1,2]});
