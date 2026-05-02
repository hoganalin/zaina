import './firebase.js';
import type { Server as HttpServer } from 'node:http';
import { serve } from '@hono/node-server';

import { app } from './app.js';
import { attachSocketServer } from './realtime.js';

const port = Number(process.env.PORT ?? 3000);

const server = serve({ fetch: app.fetch, port }, (info) => {
  console.log(`zaina-api listening on http://localhost:${info.port}`);
});

attachSocketServer(server as unknown as HttpServer);
