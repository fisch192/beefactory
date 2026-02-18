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
  const testimonials = (await store.get<any[]>('testimonials')) ?? [];

  return new Response(JSON.stringify(testimonials), {
    headers: { 'Content-Type': 'application/json' },
  });
};

export const POST: APIRoute = async ({ request }) => {
  if (!checkAuth(request)) return unauthorized();

  const store = await getStore();
  const data = await request.json();
  const testimonials = (await store.get<any[]>('testimonials')) ?? [];

  const id = crypto.randomUUID();
  const testimonial = { id, ...data };
  testimonials.push(testimonial);

  await store.put('testimonials', testimonials);

  return new Response(JSON.stringify(testimonial), {
    status: 201,
    headers: { 'Content-Type': 'application/json' },
  });
};
