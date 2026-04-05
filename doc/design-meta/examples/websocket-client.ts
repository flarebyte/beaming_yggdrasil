import type { EventEnvelope } from './common';

export type ClientMessage =
  | {
      id?: string;
      kind: 'subscribe';
      rootKeys: string[];
    }
  | {
      id?: string;
      kind: 'unsubscribe';
      rootKeys: string[];
    }
  | {
      id?: string;
      kind: 'ping';
    };

export type ServerMessage =
  | {
      id?: string;
      kind: 'subscribed';
      rootKeys?: string[];
    }
  | {
      id?: string;
      kind: 'unsubscribed';
      rootKeys?: string[];
    }
  | {
      id?: string;
      kind: 'pong';
    }
  | {
      id?: string;
      kind: 'status';
      status: string;
      message?: string;
    }
  | {
      kind: 'event';
      event: EventEnvelope;
    };

export interface BeamingYggdrasilWebSocketSession {
  send(message: ClientMessage): Promise<void>;
  messages(): AsyncIterable<ServerMessage>;
  close(): Promise<void>;
}

// Dart translation guidance:
// - keep websocket command DTOs close to the wire
// - preserve correlation ids when supplied
// - expose event messages directly rather than hiding them behind imperative callbacks only
