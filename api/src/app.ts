import { Hono } from 'hono';

import { authRoutes } from './routes/auth.js';
import { channelsRoutes } from './routes/channels.js';
import { conversationsRoutes } from './routes/conversations.js';
import { feedRoutes } from './routes/feed.js';
import { interestsRoutes } from './routes/interests.js';
import { meRoutes } from './routes/me.js';
import { postsRoutes } from './routes/posts.js';
import { usersRoutes } from './routes/users.js';

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
app.route('/api/feed', feedRoutes);
app.route('/api/posts', postsRoutes);
app.route('/api/users', usersRoutes);
app.route('/api/conversations', conversationsRoutes);
