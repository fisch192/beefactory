import { readFile, writeFile, readdir, unlink, mkdir } from 'node:fs/promises';
import { join, dirname } from 'node:path';
import { existsSync } from 'node:fs';
import type { Store } from './store';

const DATA_DIR = join(process.cwd(), 'data');

export class LocalStore implements Store {
  async get<T = unknown>(key: string): Promise<T | null> {
    const filePath = join(DATA_DIR, `${key}.json`);
    try {
      const raw = await readFile(filePath, 'utf-8');
      return JSON.parse(raw) as T;
    } catch {
      return null;
    }
  }

  async put<T = unknown>(key: string, data: T): Promise<void> {
    const filePath = join(DATA_DIR, `${key}.json`);
    const dir = dirname(filePath);
    if (!existsSync(dir)) {
      await mkdir(dir, { recursive: true });
    }
    await writeFile(filePath, JSON.stringify(data, null, 2), 'utf-8');
  }

  async list(): Promise<string[]> {
    const keys: string[] = [];
    async function scan(dir: string, prefix: string) {
      try {
        const entries = await readdir(dir, { withFileTypes: true });
        for (const entry of entries) {
          if (entry.isDirectory()) {
            await scan(join(dir, entry.name), prefix ? `${prefix}/${entry.name}` : entry.name);
          } else if (entry.name.endsWith('.json')) {
            const key = prefix ? `${prefix}/${entry.name.replace('.json', '')}` : entry.name.replace('.json', '');
            keys.push(key);
          }
        }
      } catch {
        // directory doesn't exist
      }
    }
    await scan(DATA_DIR, '');
    return keys;
  }

  async delete(key: string): Promise<void> {
    const filePath = join(DATA_DIR, `${key}.json`);
    try {
      await unlink(filePath);
    } catch {
      // file doesn't exist
    }
  }
}
