import { defineConfig } from 'vitest/config';
import { loadEnv } from 'vite';

export default defineConfig(({ mode }) => ({
  test: {
    include: ['test/**/*.test.ts'],
    environment: 'node',
    env: loadEnv(mode, process.cwd(), ''),
  },
}));
