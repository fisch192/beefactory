/**
 * Generate a password hash for ADMIN_PASSWORD_HASH env var.
 * Usage: npx tsx scripts/hash-password.ts <password>
 */
import { scrypt, randomBytes } from 'node:crypto';

const password = process.argv[2];
if (!password) {
  console.error('Usage: npx tsx scripts/hash-password.ts <password>');
  process.exit(1);
}

const salt = randomBytes(16);
scrypt(password, salt, 64, (err, key) => {
  if (err) throw err;
  const hash = `${salt.toString('hex')}:${key.toString('hex')}`;
  console.log('\nAdd to .env or Vercel environment variables:\n');
  console.log(`ADMIN_PASSWORD_HASH=${hash}`);
});
