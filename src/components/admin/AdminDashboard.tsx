import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import { getProducts, getCollections, getTestimonials, publish } from '../../lib/admin-api';

interface Stats {
  products: number;
  collections: number;
  testimonials: number;
}

export default function AdminDashboard() {
  const [stats, setStats] = useState<Stats | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [publishing, setPublishing] = useState(false);
  const [publishMsg, setPublishMsg] = useState('');

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      setLoading(true);
      const [products, collections, testimonials] = await Promise.all([
        getProducts(),
        getCollections(),
        getTestimonials(),
      ]);
      setStats({
        products: products.length,
        collections: collections.length,
        testimonials: testimonials.length,
      });
    } catch (err: any) {
      setError('Statistiken konnten nicht geladen werden.');
    } finally {
      setLoading(false);
    }
  };

  const handlePublish = async () => {
    setPublishing(true);
    setPublishMsg('');
    try {
      const res = await publish();
      setPublishMsg(res.message || 'Erfolgreich veroeffentlicht!');
    } catch (err: any) {
      setPublishMsg('Fehler beim Veroeffentlichen: ' + err.message);
    } finally {
      setPublishing(false);
    }
  };

  const statCards = [
    { label: 'Produkte', value: stats?.products ?? 0, href: '/admin/products', color: 'bg-[#D4A843]/10 text-[#D4A843]' },
    { label: 'Kategorien', value: stats?.collections ?? 0, href: '/admin/collections', color: 'bg-[#a42325]/10 text-[#a42325]' },
    { label: 'Bewertungen', value: stats?.testimonials ?? 0, href: '/admin/testimonials', color: 'bg-blue-50 text-blue-600' },
  ];

  const quickLinks = [
    { label: 'Produkte verwalten', href: '/admin/products' },
    { label: 'Kategorien verwalten', href: '/admin/collections' },
    { label: 'Bewertungen verwalten', href: '/admin/testimonials' },
    { label: 'Uebersetzungen bearbeiten', href: '/admin/translations' },
    { label: 'Einstellungen', href: '/admin/settings' },
    { label: 'Backup & Wiederherstellung', href: '/admin/backup' },
  ];

  return (
    <div class="max-w-4xl">
      <h1 class="text-2xl font-bold text-[#0f0f0f] mb-6">Dashboard</h1>

      {error && (
        <div class="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg border border-red-200 mb-6">
          {error}
        </div>
      )}

      {/* Stats */}
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
        {statCards.map((card) => (
          <a
            key={card.label}
            href={card.href}
            class="bg-white rounded-xl border border-gray-200 p-5 hover:shadow-md transition-shadow"
          >
            <div class="text-sm text-gray-500 mb-1">{card.label}</div>
            <div class="text-3xl font-bold text-[#0f0f0f]">
              {loading ? (
                <span class="inline-block w-8 h-8 bg-gray-100 rounded animate-pulse" />
              ) : (
                card.value
              )}
            </div>
          </a>
        ))}
      </div>

      {/* Publish */}
      <div class="bg-white rounded-xl border border-gray-200 p-6 mb-8">
        <h2 class="text-lg font-semibold text-[#0f0f0f] mb-2">Website veroeffentlichen</h2>
        <p class="text-sm text-gray-500 mb-4">
          Aenderungen an Produkten, Kategorien und Einstellungen werden erst nach dem Veroeffentlichen sichtbar.
        </p>
        <div class="flex items-center gap-4">
          <button
            onClick={handlePublish}
            disabled={publishing}
            class="bg-[#a42325] hover:bg-[#8a1e20] text-white font-semibold py-2.5 px-6 rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
          >
            {publishing ? 'Wird veroeffentlicht...' : 'Veroeffentlichen'}
          </button>
          {publishMsg && (
            <span class={`text-sm ${publishMsg.includes('Fehler') ? 'text-red-600' : 'text-green-600'}`}>
              {publishMsg}
            </span>
          )}
        </div>
      </div>

      {/* Quick links */}
      <div class="bg-white rounded-xl border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-[#0f0f0f] mb-4">Schnellzugriff</h2>
        <div class="grid grid-cols-1 sm:grid-cols-2 gap-2">
          {quickLinks.map((link) => (
            <a
              key={link.href}
              href={link.href}
              class="flex items-center gap-2 px-4 py-3 rounded-lg text-sm font-medium text-[#0f0f0f] hover:bg-gray-50 transition-colors border border-gray-100"
            >
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="text-gray-400">
                <path d="M9 5l7 7-7 7" />
              </svg>
              {link.label}
            </a>
          ))}
        </div>
      </div>
    </div>
  );
}
