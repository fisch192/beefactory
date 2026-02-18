import type { APIRoute } from 'astro';
import { deleteSession, COOKIE_NAME } from '../../../lib/auth';

export const POST: APIRoute = async ({ request }) => {
  const cookies = request.headers.get('cookie') ?? '';
  const match = cookies.match(new RegExp(`${COOKIE_NAME}=([^;]+)`));
  const sessionId = match?.[1];
  if (sessionId) deleteSession(sessionId);

  return new Response(JSON.stringify({ ok: true }), {
    headers: {
      'Content-Type': 'application/json',
      'Set-Cookie': `${COOKIE_NAME}=; Path=/; HttpOnly; Max-Age=0`,
    },
  });
};
