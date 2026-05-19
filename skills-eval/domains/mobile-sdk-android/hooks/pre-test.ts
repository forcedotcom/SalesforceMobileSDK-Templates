/**
 * preTest hook for the mobile-sdk-android domain.
 *
 * Logs context and warns on misconfigured cases. No side effects.
 */

import type { PreTestHookContext } from '@sfdc-internal/adk-eval';
import { existsSync } from 'node:fs';
import { join } from 'node:path';

const REQUIRED_SEED_FILES = [
  'app/build.gradle.kts',
  'app/src/main/AndroidManifest.xml',
  'gradlew',
  'settings.gradle.kts',
];

const REQUIRED_PROMPT_KEYWORDS = [
  'mobile sdk',
  'package',
  'consumer key',
  'callback',
  'login host',
];

export default async function prepareAddMobileSdkAndroid(
  ctx: PreTestHookContext,
): Promise<void> {
  console.log(`[mobile-sdk-android:preTest] ${ctx.testCaseName}`);
  console.log(`[mobile-sdk-android:preTest] Domain dir: ${ctx.domainDir}`);

  // Verify seed-data has a buildable starting point
  const caseDir = join(ctx.domainDir, 'datasets', ctx.testCaseName);
  const seedDir = join(caseDir, 'seed-data');
  for (const rel of REQUIRED_SEED_FILES) {
    const full = join(seedDir, rel);
    if (!existsSync(full)) {
      console.warn(
        `[mobile-sdk-android:preTest] Missing seed file: ${rel} ` +
          `(expected at ${full}). Case may fail to build.`,
      );
    }
  }

  // Light prompt sanity
  const promptLower = ctx.prompt.toLowerCase();
  const missing = REQUIRED_PROMPT_KEYWORDS.filter((kw) => !promptLower.includes(kw));
  if (missing.length > 0) {
    console.warn(
      `[mobile-sdk-android:preTest] Prompt missing expected keywords: ` +
        missing.join(', ') +
        '. Skill may not have enough context to proceed without follow-up.',
    );
  }

  console.log(`[mobile-sdk-android:preTest] ${ctx.testCaseName} ready`);
}
