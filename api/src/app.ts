import { Hono } from 'hono';

import { authRoutes } from './routes/auth.js';
import { channelsRoutes } from './routes/channels.js';
import { interestsRoutes } from './routes/interests.js';
import { meRoutes } from './routes/me.js';

export const app = new Hono();

app.get('/', (c) => c.json({ name: 'zaina-api', status: 'ok' }));

app.get('/health', (c) =>
  c.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
  }),
);

app.route('/api/auth', authRoutes);
app.route('/api/me', meRoutes);
app.route('/api/interests', interestsRoutes);
app.route('/api/channels', channelsRoutes);
