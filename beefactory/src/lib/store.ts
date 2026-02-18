export interface Store {
  get<T = unknown>(key: string): Promise<T | null>;
  put<T = unknown>(key: string, data: T): Promise<void>;
  list(): Promise<string[]>;
  delete(key: string): Promise<void>;
}

let _store: Store | null = null;

export async function getStore(): Promise<Store> {
  if (_store) return _store;

  if (import.meta.env.VERCEL_BLOB_READ_WRITE_TOKEN || import.meta.env.BLOB_READ_WRITE_TOKEN) {
    const { BlobStore } = await import('./store-blob');
    _store = new BlobStore();
  } else {
    const { LocalStore } = await import('./store-local');
    _store = new LocalStore();
  }
  return _store;
}
