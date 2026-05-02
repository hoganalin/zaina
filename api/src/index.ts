import './firebase.js';
import type { Server as HttpServer } from 'node:http';
import { serve } from '@hono/node-server';

import { app } from './app.js';
import { loadEnv } from './env.js';
import { attachSocketServer } from './realtime.js';

const env = loadEnv();

const server = serve({ fetch: app.fetch, port: env.PORT }, (info) => {
  console.log(`zaina-api listening on http://localhost:${info.port}`);
});

attachSocketServer(server as unknown as HttpServer);
