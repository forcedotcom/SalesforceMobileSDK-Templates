/*
 * Copyright (c) 2026-present, salesforce.com, inc.
 * All rights reserved.
 */

import assert from 'node:assert/strict';
import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import {createRequire} from 'node:module';
import path from 'node:path';

const [sourceArgument, outputArgument] = process.argv.slice(2);
assert(sourceArgument && outputArgument,
    'Usage: node scripts/check-react-native-template.ts <template> <new-output>');
const source = path.resolve(sourceArgument);
const output = path.resolve(outputArgument);
assert(!fs.existsSync(output), 'Use a new output directory to preserve prior work');
const excluded = new Set(['node_modules', 'mobile_sdk', 'ios', 'android',
    '.git', '.idea', '_local', 'coverage']);
fs.cpSync(source, output, {recursive: true,
    filter: entry => !excluded.has(path.basename(entry))});
const load = createRequire(path.join(output, 'package.json'));
const receipt = load('./installnpm.js').install(output);

function hasTypeScript(directory: string): boolean {
    return fs.readdirSync(directory, {withFileTypes: true}).some(entry => {
        if (excluded.has(entry.name)) {
            return false;
        }
        return entry.isDirectory()
            ? hasTypeScript(path.join(directory, entry.name))
            : /\.tsx?$/.test(entry.name);
    });
}

const typecheck = hasTypeScript(output);
if (typecheck) {
    execFileSync(process.execPath, [load.resolve('typescript/bin/tsc'),
        '--noEmit'], {cwd: output, stdio: 'inherit'});
}
const jest = load.resolve('jest/bin/jest');
const tests = JSON.parse(execFileSync(process.execPath, [jest, '--listTests',
    '--runInBand', '--watchman=false', '--json'], {cwd: output,
    encoding: 'utf8'}));
if (tests.length > 0) {
    execFileSync(process.execPath, [jest, '--runInBand', '--watchman=false',
        '--json', '--outputFile=jest-results.json'],
        {cwd: output, stdio: 'inherit'});
} else {
    fs.writeFileSync(path.join(output, 'jest-results.json'), JSON.stringify({
        success: true, numFailedTests: 0, numPassedTests: 0, numPendingTests: 0,
        testResults: [],
    }) + '\n');
}
const results = JSON.parse(fs.readFileSync(path.join(output,
    'jest-results.json'), 'utf8'));
assert(results.success && results.numFailedTests === 0, 'Jest checks failed');
if (path.basename(source) === 'ReactNativeTypeScriptTemplate') {
    assert(results.numPassedTests >= 4, 'Expected logout regression coverage');
}
fs.writeFileSync(path.join(output, 'checks.json'), JSON.stringify({
    ...receipt, typecheck: typecheck ? 'passed' : 'no TypeScript sources',
    testsPassed: results.numPassedTests, testsPending: results.numPendingTests,
}, null, 2) + '\n');
