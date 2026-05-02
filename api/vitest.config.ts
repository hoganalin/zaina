import { loadEnv } from 'vite';
import { defineConfig } from 'vitest/config';

export default defineConfig(({ mode }) => ({
  test: {
    include: ['test/**/*.test.ts'],
    environment: 'node',
    env: loadEnv(mode, process.cwd(), ''),
    // We share a single Neon DB across all test files. Run files sequentially
    // so concurrent inserts/deletes don't pollute each other's queries.
    fileParallelism: false,
    // Neon cold starts + sequential prisma transactions occasionally push
    // multi-step integration tests past the default 5s.
    testTimeout: 15000,
  },
}));
