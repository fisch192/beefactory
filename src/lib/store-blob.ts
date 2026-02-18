import { put as blobPut, del as blobDel, list as blobList } from '@vercel/blob';
import type { Store } from './store';

const PREFIX = 'beefactory-data/';

export class BlobStore implements Store {
  async get<T = unknown>(key: string): Promise<T | null> {
    try {
      const url = `${PREFIX}${key}.json`;
      const result = await blobList({ prefix: url, limit: 1 });
      if (result.blobs.length === 0) return null;
      const response = await fetch(result.blobs[0].url);
      if (!response.ok) return null;
      return (await response.json()) as T;
    } catch {
      return null;
    }
  }

  async put<T = unknown>(key: string, data: T): Promise<void> {
    const path = `${PREFIX}${key}.json`;
    await blobPut(path, JSON.stringify(data, null, 2), {
      access: 'public',
      addRandomSuffix: false,
    });
  }

  async list(): Promise<string[]> {
    const result = await blobList({ prefix: PREFIX, limit: 1000 });
    return result.blobs
      .map((b) => b.pathname.replace(PREFIX, '').replace('.json', ''))
      .filter(Boolean);
  }

  async delete(key: string): Promise<void> {
    try {
      const path = `${PREFIX}${key}.json`;
      const result = await blobList({ prefix: path, limit: 1 });
      if (result.blobs.length > 0) {
        await blobDel(result.blobs[0].url);
      }
    } catch {
      // blob doesn't exist
    }
  }
}
