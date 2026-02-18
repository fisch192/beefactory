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

export const GET: APIRoute = async ({ request }) => {
  if (!checkAuth(request)) return unauthorized();

  const store = await getStore();

  const keys = ['products', 'collections', 'testimonials', 'translations/de', 'translations/it', 'settings'];
  const backup: Record<string, any> = {};

  for (const key of keys) {
    backup[key] = (await store.get(key)) ?? null;
  }

  const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
  const filename = `beefactory-backup-${timestamp}.json`;

  return new Response(JSON.stringify(backup, null, 2), {
    headers: {
      'Content-Type': 'application/json',
      'Content-Disposition': `attachment; filename="${filename}"`,
    },
  });
};
