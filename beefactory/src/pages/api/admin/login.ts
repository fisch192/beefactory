import type { APIRoute } from 'astro';
import { validateCredentials, createSession, COOKIE_NAME } from '../../../lib/auth';

export const POST: APIRoute = async ({ request }) => {
  const { username, password } = await request.json();

  if (!username || !password) {
    return new Response(JSON.stringify({ error: 'Benutzername und Passwort erforderlich' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const valid = await validateCredentials(username, password);
  if (!valid) {
    return new Response(JSON.stringify({ error: 'Ungültige Anmeldedaten' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const sessionId = createSession(username);
  return new Response(JSON.stringify({ ok: true }), {
    status: 200,
    headers: {
      'Content-Type': 'application/json',
      'Set-Cookie': `${COOKIE_NAME}=${sessionId}; Path=/; HttpOnly; SameSite=Lax; Max-Age=${24 * 60 * 60}`,
    },
  });
};
