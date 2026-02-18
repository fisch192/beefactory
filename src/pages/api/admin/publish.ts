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
  const settings = (await store.get<any>('settings')) ?? {};
  const hookUrl = settings.vercelDeployHookUrl;

  if (!hookUrl) {
    return new Response(
      JSON.stringify({ ok: false, message: 'Kein Deploy-Hook konfiguriert' }),
      {
        status: 400,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }

  try {
    const res = await fetch(hookUrl, { method: 'POST' });
    if (!res.ok) {
      return new Response(
        JSON.stringify({ ok: false, message: `Deploy-Hook fehlgeschlagen: ${res.status}` }),
        {
          status: 502,
          headers: { 'Content-Type': 'application/json' },
        },
      );
    }

    return new Response(
      JSON.stringify({ ok: true, message: 'Deploy wurde ausgelöst' }),
      {
        headers: { 'Content-Type': 'application/json' },
      },
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ ok: false, message: `Fehler beim Auslösen des Deploys: ${(err as Error).message}` }),
      {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      },
    );
  }
};
