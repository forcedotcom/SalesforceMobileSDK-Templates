import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: [
      'node_modules/@sfdc-internal/adk-eval/dist-bundle/runners/knowledge.eval.js',
    ],
    server: {
      deps: {
        inline: ['@sfdc-internal/adk-eval'],
      },
    },
    exclude: [],
    setupFiles: [
      'node_modules/@sfdc-internal/adk-eval/dist-bundle/setup-env.js',
      'node_modules/@sfdc-internal/adk-eval/dist-bundle/setup-langsmith.js',
    ],
    reporters: process.env.LANGCHAIN_API_KEY
      ? ['default', 'langsmith/vitest/reporter']
      : ['default'],
    testTimeout: 900_000,
    hookTimeout: 900_000,
    pool: 'forks',
    poolOptions: {
      forks: {
        singleFork: true,
      },
    },
  },
});
