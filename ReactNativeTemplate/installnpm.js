/*
 * Copyright (c) 2026-present, salesforce.com, inc.
 * All rights reserved.
 */

const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const {execFileSync} = require('node:child_process');
const {createRequire} = require('node:module');

function verify(root) {
    const load = createRequire(path.join(root, 'package.json'));
    const app = load('./package.json');
    const bridge = load('react-native-force/package.json');
    const native = load('react-native/package.json');
    const react = load('react/package.json');
    const semver = load('semver');
    assert(semver.satisfies(native.version, app.dependencies['react-native']),
        'Installed React Native does not match the app requirement');
    assert(semver.satisfies(native.version, bridge.peerDependencies['react-native']),
        'Bridge React Native peer mismatch; select the reviewed bridge package');
    assert(semver.satisfies(react.version, bridge.peerDependencies.react),
        'Bridge React peer mismatch');
    const digest = crypto.createHash('sha256');
    for (const relative of ['package.json', 'dist/index.js', 'android/build.gradle']) {
        digest.update(fs.readFileSync(path.join(root,
            'node_modules/react-native-force', relative)));
    }
    const receipt = {bridgeVersion: bridge.version,
        reactNativeVersion: native.version, reactVersion: react.version,
        bridgeFilesSha256: digest.digest('hex')};
    fs.writeFileSync(path.join(root, 'node_modules/.msdk-source.json'),
        JSON.stringify(receipt, null, 2) + '\n');
    console.log('Verified React Native dependencies:', JSON.stringify(receipt));
    return receipt;
}

function install(root = __dirname) {
    const manifest = path.join(root, 'package.json');
    const override = process.env.MSDK_REACT_NATIVE_FORCE_PACKAGE;
    if (override) {
        const app = JSON.parse(fs.readFileSync(manifest));
        app.dependencies['react-native-force'] = override;
        fs.writeFileSync(manifest, JSON.stringify(app, null, 2) + '\n');
    }
    execFileSync('yarn', ['install'], {cwd: root, stdio: 'inherit'});
    return verify(root);
}

module.exports = {install, verify};
