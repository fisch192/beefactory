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

function notFound() {
  return new Response(JSON.stringify({ error: 'Nicht gefunden' }), {
    status: 404,
    headers: { 'Content-Type': 'application/json' },
  });
}

export const GET: APIRoute = async ({ params, request }) => {
  if (!checkAuth(request)) return unauthorized();

  const store = await getStore();
  const products = (await store.get<any[]>('products')) ?? [];
  const product = products.find((p) => p.id === params.id);

  if (!product) return notFound();

  return new Response(JSON.stringify(product), {
    headers: { 'Content-Type': 'application/json' },
  });
};

export const PUT: APIRoute = async ({ params, request }) => {
  if (!checkAuth(request)) return unauthorized();

  const store = await getStore();
  const products = (await store.get<any[]>('products')) ?? [];
  const index = products.findIndex((p) => p.id === params.id);

  if (index === -1) return notFound();

  const data = await request.json();
  products[index] = { ...products[index], ...data, id: params.id };
  await store.put('products', products);

  return new Response(JSON.stringify(products[index]), {
    headers: { 'Content-Type': 'application/json' },
  });
};

export const DELETE: APIRoute = async ({ params, request }) => {
  if (!checkAuth(request)) return unauthorized();

  const store = await getStore();
  const products = (await store.get<any[]>('products')) ?? [];
  const index = products.findIndex((p) => p.id === params.id);

  if (index === -1) return notFound();

  products.splice(index, 1);
  await store.put('products', products);

  return new Response(null, { status: 204 });
};
