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
  },
}));
