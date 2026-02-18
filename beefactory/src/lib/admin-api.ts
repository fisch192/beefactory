/** Thin fetch wrapper for admin API endpoints */

async function request<T>(url: string, options?: RequestInit): Promise<T> {
  const res = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`API error ${res.status}: ${body}`);
  }

  if (res.status === 204) return undefined as T;
  return res.json();
}

// ── Auth ─────────────────────────────────────────────────────────────────────

export async function login(username: string, password: string) {
  return request<{ ok: boolean }>('/api/admin/login', {
    method: 'POST',
    body: JSON.stringify({ username, password }),
  });
}

export async function logout() {
  return request<{ ok: boolean }>('/api/admin/logout', { method: 'POST' });
}

// ── Products ─────────────────────────────────────────────────────────────────

export async function getProducts() {
  return request<any[]>('/api/admin/products');
}

export async function getProduct(id: string) {
  return request<any>(`/api/admin/products/${encodeURIComponent(id)}`);
}

export async function createProduct(data: any) {
  return request<any>('/api/admin/products', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

export async function updateProduct(id: string, data: any) {
  return request<any>(`/api/admin/products/${encodeURIComponent(id)}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}

export async function deleteProduct(id: string) {
  return request<void>(`/api/admin/products/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  });
}

// ── Collections ──────────────────────────────────────────────────────────────

export async function getCollections() {
  return request<any[]>('/api/admin/collections');
}

export async function getCollection(id: string) {
  return request<any>(`/api/admin/collections/${encodeURIComponent(id)}`);
}

export async function createCollection(data: any) {
  return request<any>('/api/admin/collections', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

export async function updateCollection(id: string, data: any) {
  return request<any>(`/api/admin/collections/${encodeURIComponent(id)}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}

export async function deleteCollection(id: string) {
  return request<void>(`/api/admin/collections/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  });
}

// ── Testimonials ─────────────────────────────────────────────────────────────

export async function getTestimonials() {
  return request<any[]>('/api/admin/testimonials');
}

export async function getTestimonial(id: string) {
  return request<any>(`/api/admin/testimonials/${encodeURIComponent(id)}`);
}

export async function createTestimonial(data: any) {
  return request<any>('/api/admin/testimonials', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

export async function updateTestimonial(id: string, data: any) {
  return request<any>(`/api/admin/testimonials/${encodeURIComponent(id)}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}

export async function deleteTestimonial(id: string) {
  return request<void>(`/api/admin/testimonials/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  });
}

// ── Translations ─────────────────────────────────────────────────────────────

export async function getTranslations(lang: string) {
  return request<Record<string, string>>(`/api/admin/translations/${lang}`);
}

export async function updateTranslations(lang: string, data: Record<string, string>) {
  return request<{ ok: boolean }>(`/api/admin/translations/${lang}`, {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}

// ── Settings ─────────────────────────────────────────────────────────────────

export async function getSettings() {
  return request<any>('/api/admin/settings');
}

export async function updateSettings(data: any) {
  return request<{ ok: boolean }>('/api/admin/settings', {
    method: 'PUT',
    body: JSON.stringify(data),
  });
}

// ── Backup / Restore ─────────────────────────────────────────────────────────

export async function downloadBackup(): Promise<Blob> {
  const res = await fetch('/api/admin/backup');
  if (!res.ok) throw new Error('Backup failed');
  return res.blob();
}

export async function restoreBackup(data: any) {
  return request<{ ok: boolean; keys: string[] }>('/api/admin/restore', {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

// ── Publish ──────────────────────────────────────────────────────────────────

export async function publish() {
  return request<{ ok: boolean; message: string }>('/api/admin/publish', {
    method: 'POST',
  });
}

// ── Upload ───────────────────────────────────────────────────────────────────

export async function uploadImage(file: File): Promise<{ url: string }> {
  const formData = new FormData();
  formData.append('file', file);
  const res = await fetch('/api/admin/upload', {
    method: 'POST',
    body: formData,
  });
  if (!res.ok) throw new Error('Upload failed');
  return res.json();
}
