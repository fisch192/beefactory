import { defineMiddleware } from 'astro:middleware';
import { getSession, COOKIE_NAME } from './lib/auth';

export const onRequest = defineMiddleware(async (context, next) => {
  const { pathname } = context.url;

  // Only protect /admin/* routes (except /admin/login)
  if (!pathname.startsWith('/admin')) {
    return next();
  }

  // Allow login page and API login endpoint
  if (pathname === '/admin/login' || pathname === '/api/admin/login') {
    return next();
  }

  // Allow all /api/admin/* routes to check auth themselves
  if (pathname.startsWith('/api/admin/')) {
    return next();
  }

  // Check session cookie
  const sessionId = context.cookies.get(COOKIE_NAME)?.value;
  if (!sessionId || !getSession(sessionId)) {
    return context.redirect('/admin/login');
  }

  return next();
});
