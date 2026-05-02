import { Hono } from 'hono';
import { authRoutes } from './routes/auth.js';

export const app = new Hono();

app.get('/', (c) => c.json({ name: 'zaina-api', status: 'ok' }));

app.get('/health', (c) =>
  c.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  }),
);

app.route('/api/auth', authRoutes);
