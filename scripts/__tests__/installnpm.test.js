/*
 * Copyright (c) 2026-present, salesforce.com, inc.
 * All rights reserved.
 */

const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const {test} = require('node:test');

for (const template of ['ReactNativeTemplate', 'ReactNativeTypeScriptTemplate',
    'ReactNativeDeferredTemplate', 'MobileSyncExplorerReactNative']) {
    test(`${template} launches Yarn from an app directory containing spaces`, t => {
        const root = fs.mkdtempSync(path.join(os.tmpdir(), 'msdk yarn app '));
        t.after(() => fs.rmSync(root, {recursive: true, force: true}));
        const bin = path.join(root, 'test bin');
        fs.mkdirSync(bin);
        fs.writeFileSync(path.join(root, 'package.json'), JSON.stringify({
            dependencies: {'react-native': '0.87.0'},
        }));
        const launcher = `
const fs = require('node:fs');
const path = require('node:path');
function write(relative, contents) {
    const file = path.join(process.cwd(), relative);
    fs.mkdirSync(path.dirname(file), {recursive: true});
    fs.writeFileSync(file, contents);
}
write('yarn-invocation.json', JSON.stringify({args: process.argv.slice(2), cwd: process.cwd()}));
write('node_modules/react-native/package.json', JSON.stringify({version: '0.87.0'}));
write('node_modules/react/package.json', JSON.stringify({version: '19.2.3'}));
write('node_modules/react-native-force/package.json', JSON.stringify({
    version: '14.1.0', peerDependencies: {'react-native': '0.87.0', react: '19.2.3'},
}));
write('node_modules/react-native-force/dist/index.js', 'exports.fixture = true;');
write('node_modules/react-native-force/android/build.gradle', '// fixture');
write('node_modules/semver/index.js', 'exports.satisfies = (version, range) => version === range;');
`;
        fs.writeFileSync(path.join(bin, 'yarn.js'), launcher);
        if (process.platform === 'win32') {
            fs.writeFileSync(path.join(bin, 'yarn.cmd'),
                `@"${process.execPath}" "%~dp0yarn.js" %*\r\n`);
        } else {
            fs.writeFileSync(path.join(bin, 'yarn'),
                '#!/usr/bin/env node\n' + launcher, {mode: 0o755});
        }
        const originalPath = process.env.PATH;
        const originalOverride = process.env.MSDK_REACT_NATIVE_FORCE_PACKAGE;
        t.after(() => {
            process.env.PATH = originalPath;
            if (originalOverride === undefined) {
                delete process.env.MSDK_REACT_NATIVE_FORCE_PACKAGE;
            } else {
                process.env.MSDK_REACT_NATIVE_FORCE_PACKAGE = originalOverride;
            }
        });
        process.env.PATH = bin + path.delimiter + originalPath;
        delete process.env.MSDK_REACT_NATIVE_FORCE_PACKAGE;
        const receipt = require(`../../${template}/installnpm`).install(root);
        const invocation = JSON.parse(fs.readFileSync(path.join(root,
            'yarn-invocation.json')));
        assert.deepEqual(invocation.args, ['install']);
        assert.equal(fs.realpathSync(invocation.cwd), fs.realpathSync(root));
        assert.equal(receipt.reactNativeVersion, '0.87.0');
        assert.deepEqual(JSON.parse(fs.readFileSync(path.join(root,
            'node_modules/.msdk-source.json'))), receipt);
    });
}
