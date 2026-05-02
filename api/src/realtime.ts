import type { Server as HttpServer } from 'node:http';
import { getAuth } from 'firebase-admin/auth';
import { Server as SocketServer } from 'socket.io';

import { prisma } from './db.js';

let io: SocketServer | null = null;

export function attachSocketServer(httpServer: HttpServer): SocketServer {
  if (io) return io;
  io = new SocketServer(httpServer, {
    cors: { origin: '*' },
  });

  io.use(async (socket, next) => {
    const token = socket.handshake.auth?.token as string | undefined;
    if (!token) return next(new Error('unauthorized'));
    try {
      const decoded = await getAuth().verifyIdToken(token);
      const user = await prisma.user.findUnique({
        where: { firebaseUid: decoded.uid },
        select: { id: true },
      });
      if (!user) return next(new Error('unauthorized'));
      socket.data.userId = user.id;
      next();
    } catch {
      next(new Error('unauthorized'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.data.userId as string;
    socket.join(`user:${userId}`);
  });

  return io;
}

export function emitToUser(
  userId: string,
  event: string,
  payload: unknown,
): void {
  io?.to(`user:${userId}`).emit(event, payload);
}
