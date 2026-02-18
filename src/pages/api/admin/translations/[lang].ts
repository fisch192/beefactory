import type { APIRoute } from 'astro';
import { getSession, COOKIE_NAME } from '../../../../lib/auth';
import { getStore } from '../../../../lib/store';

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

export const GET: APIRoute = async ({ params, request }) => {
  if (!checkAuth(request)) return unauthorized();

  const lang = params.lang;
  if (!lang) {
    return new Response(JSON.stringify({ error: 'Sprache erforderlich' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const store = await getStore();
  const translations = (await store.get<Record<string, string>>(`translations/${lang}`)) ?? {};

  return new Response(JSON.stringify(translations), {
    headers: { 'Content-Type': 'application/json' },
  });
};

export const PUT: APIRoute = async ({ params, request }) => {
  if (!checkAuth(request)) return unauthorized();

  const lang = params.lang;
  if (!lang) {
    return new Response(JSON.stringify({ error: 'Sprache erforderlich' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const store = await getStore();
  const data = await request.json();
  await store.put(`translations/${lang}`, data);

  return new Response(JSON.stringify({ ok: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
};
