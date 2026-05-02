import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  PORT: z.coerce.number().int().positive().default(3000),
  // Either explicit service-account file path (local dev) or rely on the
  // ambient credentials Cloud Run / Cloud Functions / GAE inject.
  FIREBASE_SERVICE_ACCOUNT_PATH: z.string().optional(),
  FIREBASE_PROJECT_ID: z.string().optional(),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
});

export type Env = z.infer<typeof envSchema>;

export function loadEnv(): Env {
  const parsed = envSchema.safeParse(process.env);
  if (!parsed.success) {
    const issues = parsed.error.issues
      .map((i) => `  - ${i.path.join('.')}: ${i.message}`)
      .join('\n');
    console.error(`[env] invalid environment:\n${issues}`);
    process.exit(1);
  }
  return parsed.data;
}
