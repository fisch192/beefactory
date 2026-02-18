import { h } from 'preact';
import { useState } from 'preact/hooks';
import { login } from '../../lib/admin-api';

export default function LoginForm() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(username, password);
      window.location.href = '/admin/';
    } catch (err: any) {
      setError('Anmeldung fehlgeschlagen. Bitte pruefen Sie Ihre Zugangsdaten.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div class="min-h-screen flex items-center justify-center px-4">
      <div class="w-full max-w-sm">
        {/* Logo */}
        <div class="text-center mb-8">
          <div class="inline-flex items-center gap-2 mb-2">
            <svg width="40" height="40" viewBox="0 0 40 40" fill="none">
              <circle cx="20" cy="20" r="18" fill="#D4A843" opacity="0.15" />
              <text x="20" y="26" text-anchor="middle" fill="#D4A843" font-size="20" font-weight="bold">B</text>
            </svg>
          </div>
          <h1 class="text-2xl font-bold text-[#0f0f0f]">BEE FACTORY</h1>
          <span class="inline-block mt-1 text-xs font-medium bg-[#D4A843] text-white px-2 py-0.5 rounded-full uppercase tracking-wider">
            Admin
          </span>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} class="bg-white rounded-xl shadow-lg p-6 space-y-5 border border-gray-100">
          {error && (
            <div class="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg border border-red-200">
              {error}
            </div>
          )}

          <div class="space-y-1">
            <label class="block text-sm font-medium text-[#0f0f0f]" for="username">
              Benutzername
            </label>
            <input
              id="username"
              type="text"
              value={username}
              onInput={(e) => setUsername((e.target as HTMLInputElement).value)}
              class="w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm focus:border-[#D4A843] focus:ring-2 focus:ring-[#D4A843]/20 focus:outline-none transition-colors"
              required
              autoFocus
              placeholder="admin"
            />
          </div>

          <div class="space-y-1">
            <label class="block text-sm font-medium text-[#0f0f0f]" for="password">
              Passwort
            </label>
            <input
              id="password"
              type="password"
              value={password}
              onInput={(e) => setPassword((e.target as HTMLInputElement).value)}
              class="w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm focus:border-[#D4A843] focus:ring-2 focus:ring-[#D4A843]/20 focus:outline-none transition-colors"
              required
              placeholder="••••••••"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            class="w-full bg-[#D4A843] hover:bg-[#c49a3a] text-white font-semibold py-2.5 px-4 rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {loading ? 'Wird angemeldet...' : 'Anmelden'}
          </button>
        </form>
      </div>
    </div>
  );
}
