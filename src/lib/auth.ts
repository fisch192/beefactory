import { scrypt, randomBytes, timingSafeEqual } from 'node:crypto';

// ── Session store (in-memory, 24h expiry) ─────────────────────────────────────

interface Session {
  user: string;
  expiresAt: number;
}

const sessions = new Map<string, Session>();
const SESSION_TTL = 24 * 60 * 60 * 1000; // 24 hours
export const COOKIE_NAME = 'bf-admin-session';

export function createSession(user: string): string {
  const id = randomBytes(32).toString('hex');
  sessions.set(id, { user, expiresAt: Date.now() + SESSION_TTL });
  return id;
}

export function getSession(id: string): Session | null {
  const session = sessions.get(id);
  if (!session) return null;
  if (Date.now() > session.expiresAt) {
    sessions.delete(id);
    return null;
  }
  return session;
}

export function deleteSession(id: string): void {
  sessions.delete(id);
}

// ── Password verification ──────────────────────────────────────────────────────

function scryptAsync(password: string, salt: Buffer, keyLen: number): Promise<Buffer> {
  return new Promise((resolve, reject) => {
    scrypt(password, salt, keyLen, (err, key) => {
      if (err) reject(err);
      else resolve(key);
    });
  });
}

/**
 * Hash format: `salt:hash` (both hex-encoded)
 * salt = 16 bytes, key = 64 bytes
 */
export async function hashPassword(password: string): Promise<string> {
  const salt = randomBytes(16);
  const key = await scryptAsync(password, salt, 64);
  return `${salt.toString('hex')}:${key.toString('hex')}`;
}

export async function verifyPassword(password: string, storedHash: string): Promise<boolean> {
  try {
    const [saltHex, keyHex] = storedHash.split(':');
    if (!saltHex || !keyHex) return false;
    const salt = Buffer.from(saltHex, 'hex');
    const storedKey = Buffer.from(keyHex, 'hex');
    const derivedKey = await scryptAsync(password, salt, 64);
    return timingSafeEqual(storedKey, derivedKey);
  } catch {
    return false;
  }
}

// ── Credential check ───────────────────────────────────────────────────────────

export async function validateCredentials(username: string, password: string): Promise<boolean> {
  const adminUser = import.meta.env.ADMIN_USER ?? process.env.ADMIN_USER;
  const adminHash = import.meta.env.ADMIN_PASSWORD_HASH ?? process.env.ADMIN_PASSWORD_HASH;

  if (!adminUser || !adminHash) return false;
  if (username !== adminUser) return false;

  return verifyPassword(password, adminHash);
}
