/**
 * postTest hook for the mobile-sdk-android domain.
 *
 * Authoritative pass/fail.
 *   1. Env precheck (JDK, ANDROID_HOME, compileSdk platform).
 *   2. ./gradlew assembleDebug in the agent's workspace dir.
 *
 * No bespoke structural assertions — gold-file diffing + the build itself
 * cover correctness. The build is the load-bearing safety net: a transformed
 * app that doesn't compile is broken regardless of what it looks like.
 */

import type { PostTestHookContext, QualityCheckResult } from '@sfdc-internal/adk-eval';
import { spawn, spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join } from 'node:path';

export default async function validateAddMobileSdkAndroid(
  ctx: PostTestHookContext,
): Promise<QualityCheckResult[]> {
  const results: QualityCheckResult[] = [];

  // ---- Env precheck -------------------------------------------------------
  results.push(...checkEnvironment());
  if (results.some((r) => !r.passed)) {
    return results;
  }

  // ---- Real Gradle build --------------------------------------------------
  results.push(await runGradleAssembleDebug(ctx));

  return results;
}

// ---------------------------------------------------------------------------
// Environment precheck
// ---------------------------------------------------------------------------

function checkEnvironment(): QualityCheckResult[] {
  const results: QualityCheckResult[] = [];

  // JDK 17 — `java -version` exits 0 but writes the version banner to stderr,
  // so we use spawnSync to capture both streams without invoking a shell.
  let jdkOk = false;
  let jdkMessage = 'java not on PATH';
  const probe = spawnSync('java', ['-version'], { encoding: 'utf-8' });
  if (probe.error) {
    /* jdkOk stays false with default 'java not on PATH' message */
  } else {
    const combined = (probe.stdout ?? '') + (probe.stderr ?? '');
    const m = combined.match(/version "(\d+)/);
    if (m && Number(m[1]) >= 17) {
      jdkOk = true;
      jdkMessage = `JDK ${m[1]} detected`;
    } else if (combined) {
      jdkMessage = `JDK >= 17 required; found: ${combined.split('\n')[0]}`;
    }
  }
  results.push({
    name: 'env:jdk-17',
    passed: jdkOk,
    message: jdkMessage,
    severity: 'error',
  });

  // ANDROID_HOME
  const androidHome = process.env.ANDROID_HOME ?? process.env.ANDROID_SDK_ROOT;
  const androidHomeOk = !!androidHome && existsSync(androidHome);
  results.push({
    name: 'env:android-home',
    passed: androidHomeOk,
    message: androidHomeOk
      ? `ANDROID_HOME=${androidHome}`
      : 'ANDROID_HOME (or ANDROID_SDK_ROOT) is unset or points at a non-existent directory',
    severity: 'error',
  });

  // compileSdk 36 platform installed
  if (androidHomeOk) {
    const platform36 = join(androidHome!, 'platforms', 'android-36');
    const platformOk = existsSync(platform36);
    results.push({
      name: 'env:android-platform-36',
      passed: platformOk,
      message: platformOk
        ? 'android-36 platform installed'
        : `Missing ${platform36}. Run: sdkmanager "platforms;android-36"`,
      severity: 'error',
    });
  }

  return results;
}

// ---------------------------------------------------------------------------
// ./gradlew assembleDebug
// ---------------------------------------------------------------------------

const GRADLE_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes

async function runGradleAssembleDebug(
  ctx: PostTestHookContext,
): Promise<QualityCheckResult> {
  if (!ctx.outputDir) {
    return {
      name: 'compile:assembleDebug',
      passed: false,
      message:
        'ctx.outputDir is undefined — runner did not expose a writable workspace ' +
        '(non-vibes surface?); cannot run gradle build',
      severity: 'error',
    };
  }

  const workdir = ctx.outputDir;
  const gradlew = join(workdir, 'gradlew');
  if (!existsSync(gradlew)) {
    return {
      name: 'compile:assembleDebug',
      passed: false,
      message: `gradlew not found at ${gradlew} — agent likely deleted or moved seed files`,
      severity: 'error',
    };
  }

  return new Promise((resolve) => {
    const child = spawn(gradlew, ['assembleDebug', '--no-daemon', '--console=plain'], {
      cwd: workdir,
      env: process.env,
    });
    const chunks: string[] = [];
    child.stdout.on('data', (d) => chunks.push(d.toString()));
    child.stderr.on('data', (d) => chunks.push(d.toString()));

    const timer = setTimeout(() => {
      child.kill('SIGKILL');
      resolve({
        name: 'compile:assembleDebug',
        passed: false,
        message:
          `Timed out after ${GRADLE_TIMEOUT_MS / 1000}s. ` +
          `Last output:\n${tail(chunks.join(''), 50)}`,
        severity: 'error',
      });
    }, GRADLE_TIMEOUT_MS);

    child.on('close', (code) => {
      clearTimeout(timer);
      const passed = code === 0;
      resolve({
        name: 'compile:assembleDebug',
        passed,
        message: passed
          ? 'BUILD SUCCESSFUL'
          : `Exit code ${code}. Last output:\n${tail(chunks.join(''), 50)}`,
        severity: 'error',
      });
    });
  });
}

function tail(s: string, lines: number): string {
  const arr = s.split('\n');
  return arr.slice(Math.max(0, arr.length - lines)).join('\n');
}
