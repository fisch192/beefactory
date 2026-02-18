import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import { getSettings, updateSettings } from '../../lib/admin-api';
import FormField from './FormField';

export default function SettingsEditor() {
  const [siteName, setSiteName] = useState('');
  const [siteUrl, setSiteUrl] = useState('');
  const [announcementDe, setAnnouncementDe] = useState('');
  const [announcementIt, setAnnouncementIt] = useState('');
  const [vercelDeployHookUrl, setVercelDeployHookUrl] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');
  const [successMsg, setSuccessMsg] = useState('');

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      setLoading(true);
      setError('');
      const data = await getSettings();
      setSiteName(data.siteName ?? '');
      setSiteUrl(data.siteUrl ?? '');
      setAnnouncementDe(data.announcementDe ?? '');
      setAnnouncementIt(data.announcementIt ?? '');
      setVercelDeployHookUrl(data.vercelDeployHookUrl ?? '');
    } catch (err: any) {
      setError('Einstellungen konnten nicht geladen werden: ' + err.message);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async (e: Event) => {
    e.preventDefault();
    setSaving(true);
    setError('');
    setSuccessMsg('');
    try {
      await updateSettings({
        siteName,
        siteUrl,
        announcementDe,
        announcementIt,
        vercelDeployHookUrl,
      });
      setSuccessMsg('Einstellungen erfolgreich gespeichert!');
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
    <div class="max-w-2xl">
      <h1 class="text-2xl font-bold text-[#0f0f0f] mb-6">Einstellungen</h1>

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

      <form onSubmit={handleSave} class="bg-white rounded-xl border border-gray-200 p-6 space-y-5">
        <FormField
          label="Seitenname"
          value={siteName}
          onChange={setSiteName}
          required
          placeholder="Bee Factory"
        />

        <FormField
          label="Seiten-URL"
          value={siteUrl}
          onChange={setSiteUrl}
          placeholder="https://beefactory.it"
        />

        <FormField
          label="Ankuendigung (Deutsch)"
          value={announcementDe}
          onChange={setAnnouncementDe}
          placeholder="Aktuelle Ankuendigung fuer die Website..."
        />

        <FormField
          label="Ankuendigung (Italiano)"
          value={announcementIt}
          onChange={setAnnouncementIt}
          placeholder="Annuncio attuale per il sito..."
        />

        <FormField
          label="Vercel Deploy Hook URL"
          value={vercelDeployHookUrl}
          onChange={setVercelDeployHookUrl}
          placeholder="https://api.vercel.com/v1/integrations/deploy/..."
        />

        <div class="pt-4 border-t border-gray-200">
          <button
            type="submit"
            disabled={saving}
            class="bg-[#D4A843] hover:bg-[#c49a3a] text-white font-semibold py-2 px-6 rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed text-sm"
          >
            {saving ? 'Wird gespeichert...' : 'Speichern'}
          </button>
        </div>
      </form>
    </div>
  );
}
