import { h } from 'preact';
import { useState, useEffect, useMemo } from 'preact/hooks';
import { getTranslations, updateTranslations } from '../../lib/admin-api';

export default function TranslationEditor() {
  const [translationsDe, setTranslationsDe] = useState<Record<string, string>>({});
  const [translationsIt, setTranslationsIt] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');
  const [filter, setFilter] = useState('');

  useEffect(() => {
    loadTranslations();
  }, []);

  const loadTranslations = async () => {
    try {
      setLoading(true);
      setError('');
      const [de, it] = await Promise.all([
        getTranslations('de'),
        getTranslations('it'),
      ]);
      setTranslationsDe(de);
      setTranslationsIt(it);
    } catch (err: any) {
      setError('Uebersetzungen konnten nicht geladen werden: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const allKeys = useMemo(() => {
    const keys = new Set([
      ...Object.keys(translationsDe),
      ...Object.keys(translationsIt),
    ]);
    return Array.from(keys).sort();
  }, [translationsDe, translationsIt]);

  const filteredKeys = useMemo(() => {
    if (!filter) return allKeys;
    const lower = filter.toLowerCase();
    return allKeys.filter(
      (key) =>
        key.toLowerCase().includes(lower) ||
        (translationsDe[key] ?? '').toLowerCase().includes(lower) ||
        (translationsIt[key] ?? '').toLowerCase().includes(lower)
    );
  }, [allKeys, filter, translationsDe, translationsIt]);

  const updateDe = (key: string, value: string) => {
    setTranslationsDe({ ...translationsDe, [key]: value });
  };

  const updateIt = (key: string, value: string) => {
    setTranslationsIt({ ...translationsIt, [key]: value });
  };

  const handleSave = async () => {
    setSaving(true);
    setError('');
    setSuccessMsg('');
    try {
      await Promise.all([
        updateTranslations('de', translationsDe),
        updateTranslations('it', translationsIt),
      ]);
      setSuccessMsg('Uebersetzungen erfolgreich gespeichert!');
      setTimeout(() => setSuccessMsg(''), 3000);
    } catch (err: any) {
      setError('Fehler beim Speichern: ' + err.message);
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div class="text-center py-12 text-gray-500">Wird geladen...</div>;
  }

  return (
    <div class="max-w-6xl">
      <div class="flex items-center justify-between mb-6">
        <h1 class="text-2xl font-bold text-[#0f0f0f]">Uebersetzungen</h1>
        <button
          onClick={handleSave}
          disabled={saving}
          class="bg-[#D4A843] hover:bg-[#c49a3a] text-white font-semibold py-2 px-5 rounded-lg transition-colors text-sm disabled:opacity-60 disabled:cursor-not-allowed"
        >
          {saving ? 'Wird gespeichert...' : 'Speichern'}
        </button>
      </div>

      {error && (
        <div class="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg border border-red-200 mb-4">
          {error}
        </div>
      )}

      {successMsg && (
        <div class="bg-green-50 text-green-700 text-sm px-4 py-3 rounded-lg border border-green-200 mb-4">
          {successMsg}
        </div>
      )}

      {/* Filter */}
      <div class="mb-4">
        <input
          type="text"
          value={filter}
          onInput={(e) => setFilter((e.target as HTMLInputElement).value)}
          placeholder="Suchen nach Schluessel oder Text..."
          class="w-full max-w-md rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-[#D4A843] focus:ring-2 focus:ring-[#D4A843]/20 focus:outline-none transition-colors"
        />
      </div>

      <div class="text-xs text-gray-500 mb-2">
        {filteredKeys.length} von {allKeys.length} Eintraegen
      </div>

      {/* Table */}
      <div class="overflow-x-auto rounded-lg border border-gray-200">
        <table class="w-full text-sm">
          <thead>
            <tr class="bg-gray-50 border-b border-gray-200">
              <th class="text-left px-4 py-3 font-semibold text-[#0f0f0f] w-1/4">Schluessel</th>
              <th class="text-left px-4 py-3 font-semibold text-[#0f0f0f] w-[37.5%]">Deutsch</th>
              <th class="text-left px-4 py-3 font-semibold text-[#0f0f0f] w-[37.5%]">Italiano</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            {filteredKeys.map((key) => (
              <tr key={key} class="hover:bg-gray-50/50">
                <td class="px-4 py-2 font-mono text-xs text-gray-500 align-top pt-3 break-all">
                  {key}
                </td>
                <td class="px-4 py-2">
                  <input
                    type="text"
                    value={translationsDe[key] ?? ''}
                    onInput={(e) => updateDe(key, (e.target as HTMLInputElement).value)}
                    class="w-full rounded border border-gray-200 px-2 py-1.5 text-sm focus:border-[#D4A843] focus:ring-1 focus:ring-[#D4A843]/20 focus:outline-none"
                  />
                </td>
                <td class="px-4 py-2">
                  <input
                    type="text"
                    value={translationsIt[key] ?? ''}
                    onInput={(e) => updateIt(key, (e.target as HTMLInputElement).value)}
                    class="w-full rounded border border-gray-200 px-2 py-1.5 text-sm focus:border-[#D4A843] focus:ring-1 focus:ring-[#D4A843]/20 focus:outline-none"
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {filteredKeys.length === 0 && (
        <div class="text-center py-8 text-gray-500 text-sm">
          Keine Uebersetzungen gefunden.
        </div>
      )}
    </div>
  );
}
