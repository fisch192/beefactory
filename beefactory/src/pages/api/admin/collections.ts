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
  const collections = (await store.get<any[]>('collections')) ?? [];

  return new Response(JSON.stringify(collections), {
    headers: { 'Content-Type': 'application/json' },
  });
};

export const POST: APIRoute = async ({ request }) => {
  if (!checkAuth(request)) return unauthorized();

  const store = await getStore();
  const data = await request.json();
  const collections = (await store.get<any[]>('collections')) ?? [];

  const id = crypto.randomUUID();
  const collection = { id, ...data };
  collections.push(collection);

  await store.put('collections', collections);

  return new Response(JSON.stringify(collection), {
    status: 201,
    headers: { 'Content-Type': 'application/json' },
  });
};
