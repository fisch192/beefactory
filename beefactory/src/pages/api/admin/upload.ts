import type { APIRoute } from 'astro';
import { getSession, COOKIE_NAME } from '../../../lib/auth';

function checkAuth(request: Request): boolean {
  const cookies = request.headers.get('cookie') ?? '';
  const match = cookies.match(new RegExp(`${COOKIE_NAME}=([^;]+)`));
  const sessionId = match?.[1];
  return !!(sessionId && getSession(sessionId));
}

export const POST: APIRoute = async ({ request }) => {
  if (!checkAuth(request)) {
    return new Response(JSON.stringify({ error: 'Nicht autorisiert' }), {
      status: 401,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const formData = await request.formData();
  const file = formData.get('file') as File | null;
  if (!file) {
    return new Response(JSON.stringify({ error: 'Keine Datei' }), {
      status: 400,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const token = import.meta.env.BLOB_READ_WRITE_TOKEN ?? process.env.BLOB_READ_WRITE_TOKEN;

  if (token) {
    // Vercel Blob upload
    const { put } = await import('@vercel/blob');
    const blob = await put(`uploads/${Date.now()}-${file.name}`, file, {
      access: 'public',
      addRandomSuffix: false,
    });
    return new Response(JSON.stringify({ url: blob.url }), {
      headers: { 'Content-Type': 'application/json' },
    });
  } else {
    // Local filesystem upload
    const { writeFile, mkdir } = await import('node:fs/promises');
    const { join } = await import('node:path');
    const { existsSync } = await import('node:fs');

    const uploadDir = join(process.cwd(), 'public', 'uploads');
    if (!existsSync(uploadDir)) await mkdir(uploadDir, { recursive: true });

    const filename = `${Date.now()}-${file.name}`;
    const buffer = Buffer.from(await file.arrayBuffer());
    await writeFile(join(uploadDir, filename), buffer);

    return new Response(JSON.stringify({ url: `/uploads/${filename}` }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }
};
