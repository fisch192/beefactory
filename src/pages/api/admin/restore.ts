import type { APIRoute } from 'astro';
import { getSession, COOKIE_NAME } from '../../../lib/auth';
import { getStore } from '../../../lib/store';

function checkAuth(request: Request): boolean {
  const cookies = request.headers.get('cookie') ?? '';
  const match = cookies.match(new RegExp(`${COOKIE_NAME}=([^;]+)`));
  const sessionId = match?.[1];
  return !!(sessionId && getSession(sessionId));
}

function unauthorized() {
  return new Response(JSON.stringify({ error: 'Nicht autorisiert' }), {
    status: 401,
    headers: { 'Content-Type': 'application/json' },
  });
}

export const POST: APIRoute = async ({ request }) => {
  if (!checkAuth(request)) return unauthorized();

  const store = await getStore();
  const data = await request.json();

  if (!data || typeof data !== 'object') {
    return new Response(JSON.stringify({ error: 'Ungültige Backup-Daten' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const keys: string[] = [];
  for (const [key, value] of Object.entries(data)) {
    await store.put(key, value);
    keys.push(key);
  }

  return new Response(JSON.stringify({ ok: true, keys }), {
    headers: { 'Content-Type': 'application/json' },
  });
};
