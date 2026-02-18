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
  const products = (await store.get<any[]>('products')) ?? [];

  return new Response(JSON.stringify(products), {
    headers: { 'Content-Type': 'application/json' },
  });
};

export const POST: APIRoute = async ({ request }) => {
  if (!checkAuth(request)) return unauthorized();

  const store = await getStore();
  const data = await request.json();
  const products = (await store.get<any[]>('products')) ?? [];

  const id = crypto.randomUUID();
  const product = { id, ...data };
  products.push(product);

  await store.put('products', products);

  return new Response(JSON.stringify(product), {
    status: 201,
    headers: { 'Content-Type': 'application/json' },
  });
};
