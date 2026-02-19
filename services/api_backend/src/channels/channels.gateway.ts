import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { ChannelsService } from './channels.service.js';

interface AuthSocket extends Socket {
  userId?: string;
  displayName?: string;
}

@WebSocketGateway({
  namespace: '/chat',
  cors: { origin: '*' },
})
export class ChannelsGateway
  implements OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server!: Server;

  private topicMembers = new Map<string, Set<string>>(); // topicId → socketIds

  constructor(
    private readonly jwtService: JwtService,
    private readonly channelsService: ChannelsService,
  ) {}

  async handleConnection(client: AuthSocket) {
    try {
      const token =
        client.handshake.auth?.['token'] ??
        client.handshake.headers?.['authorization']?.replace('Bearer ', '');
      if (!token) {
        client.disconnect();
        return;
      }
      const payload = this.jwtService.verify(token);
      client.userId = payload.sub;
      client.displayName = payload.displayName ?? payload.email;
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(client: AuthSocket) {
    // Remove from all topic rooms
    for (const [topicId, members] of this.topicMembers) {
      members.delete(client.id);
      if (members.size === 0) this.topicMembers.delete(topicId);
    }
  }

  @SubscribeMessage('join_topic')
  handleJoinTopic(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody() data: { topicId: string },
  ) {
    const { topicId } = data;
    client.join(`topic:${topicId}`);
    if (!this.topicMembers.has(topicId)) {
      this.topicMembers.set(topicId, new Set());
    }
    this.topicMembers.get(topicId)!.add(client.id);

    // Notify others in the topic
    client.to(`topic:${topicId}`).emit('user_joined', {
      userId: client.userId,
      displayName: client.displayName,
    });

    return { event: 'joined', topicId };
  }

  @SubscribeMessage('leave_topic')
  handleLeaveTopic(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody() data: { topicId: string },
  ) {
    const { topicId } = data;
    client.leave(`topic:${topicId}`);
    this.topicMembers.get(topicId)?.delete(client.id);

    client.to(`topic:${topicId}`).emit('user_left', {
      userId: client.userId,
      displayName: client.displayName,
    });

    return { event: 'left', topicId };
  }

  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody()
    data: {
      topicId: string;
      body: string;
      photoUrl?: string;
      replyToId?: string;
    },
  ) {
    if (!client.userId) return;

    try {
      const message = await this.channelsService.sendMessage(client.userId, {
        topicId: data.topicId,
        body: data.body,
        photoUrl: data.photoUrl,
        replyToId: data.replyToId,
      });

      // Broadcast to everyone in the topic (including sender)
      this.server.to(`topic:${data.topicId}`).emit('new_message', message);

      return { event: 'message_sent', messageId: message.id };
    } catch (err: unknown) {
      const errorMessage = err instanceof Error ? err.message : 'Failed to send message';
      return { event: 'error', message: errorMessage };
    }
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody() data: { topicId: string },
  ) {
    client.to(`topic:${data.topicId}`).emit('user_typing', {
      userId: client.userId,
      displayName: client.displayName,
    });
  }

  @SubscribeMessage('stop_typing')
  handleStopTyping(
    @ConnectedSocket() client: AuthSocket,
    @MessageBody() data: { topicId: string },
  ) {
    client.to(`topic:${data.topicId}`).emit('user_stop_typing', {
      userId: client.userId,
    });
  }
}
