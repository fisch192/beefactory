import { h } from 'preact';
import { logout } from '../../lib/admin-api';

interface AdminNavProps {
  active: string;
}

const navItems = [
  { key: 'dashboard', label: 'Dashboard', href: '/admin/', icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-4 0a1 1 0 01-1-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 01-1 1' },
  { key: 'products', label: 'Produkte', href: '/admin/products', icon: 'M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4' },
  { key: 'collections', label: 'Kategorien', href: '/admin/collections', icon: 'M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10' },
  { key: 'testimonials', label: 'Bewertungen', href: '/admin/testimonials', icon: 'M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z' },
  { key: 'translations', label: 'Uebersetzungen', href: '/admin/translations', icon: 'M3 5h12M9 3v2m1.048 9.5A18.022 18.022 0 016.412 9m6.088 9h7M11 21l5-10 5 10M12.751 5C11.783 10.77 8.07 15.61 3 18.129' },
  { key: 'settings', label: 'Einstellungen', href: '/admin/settings', icon: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z M15 12a3 3 0 11-6 0 3 3 0 016 0z' },
  { key: 'backup', label: 'Backup', href: '/admin/backup', icon: 'M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4' },
];

export default function AdminNav({ active }: AdminNavProps) {
  const handleLogout = async () => {
    try {
      await logout();
    } catch {
      // ignore
    }
    window.location.href = '/admin/login';
  };

  return (
    <nav class="w-[250px] min-h-screen bg-[#0f0f0f] flex flex-col shrink-0">
      {/* Logo */}
      <div class="px-5 py-6 border-b border-white/10">
        <a href="/admin/" class="block">
          <div class="text-white font-bold text-lg tracking-wide">BEE FACTORY</div>
          <span class="inline-block mt-1 text-[10px] font-semibold bg-[#D4A843] text-white px-2 py-0.5 rounded-full uppercase tracking-widest">
            Admin
          </span>
        </a>
      </div>

      {/* Navigation */}
      <div class="flex-1 py-4 px-3 space-y-1">
        {navItems.map((item) => {
          const isActive = active === item.key;
          return (
            <a
              key={item.key}
              href={item.href}
              class={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                isActive
                  ? 'bg-[#D4A843]/15 text-[#D4A843]'
                  : 'text-gray-400 hover:text-white hover:bg-white/5'
              }`}
            >
              <svg
                width="20"
                height="20"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                stroke-width="1.5"
                stroke-linecap="round"
                stroke-linejoin="round"
                class="shrink-0"
              >
                <path d={item.icon} />
              </svg>
              {item.label}
            </a>
          );
        })}
      </div>

      {/* Logout */}
      <div class="px-3 pb-4">
        <button
          onClick={handleLogout}
          class="flex items-center gap-3 w-full px-3 py-2.5 rounded-lg text-sm font-medium text-gray-400 hover:text-red-400 hover:bg-red-400/5 transition-colors"
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.5"
            stroke-linecap="round"
            stroke-linejoin="round"
            class="shrink-0"
          >
            <path d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
          </svg>
          Abmelden
        </button>
      </div>
    </nav>
  );
}
