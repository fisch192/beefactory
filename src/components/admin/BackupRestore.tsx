import { h } from 'preact';
import { useState, useRef } from 'preact/hooks';
import { downloadBackup, restoreBackup } from '../../lib/admin-api';

export default function BackupRestore() {
  const [downloading, setDownloading] = useState(false);
  const [restoring, setRestoring] = useState(false);
  const [error, setError] = useState('');
  const [restoreResult, setRestoreResult] = useState<{ ok: boolean; keys: string[] } | null>(null);
  const [backupData, setBackupData] = useState<any | null>(null);
  const [fileName, setFileName] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleDownload = async () => {
    setDownloading(true);
    setError('');
    try {
      const blob = await downloadBackup();
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `beefactory-backup-${new Date().toISOString().slice(0, 10)}.json`;
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      URL.revokeObjectURL(url);
    } catch (err: any) {
      setError('Backup-Download fehlgeschlagen: ' + err.message);
    } finally {
      setDownloading(false);
    }
  };

  const handleFileSelect = async (e: Event) => {
    const input = e.target as HTMLInputElement;
    if (!input.files?.length) return;
    const file = input.files[0];
    setFileName(file.name);
    setRestoreResult(null);
    setError('');

    try {
      const text = await file.text();
      const data = JSON.parse(text);
      setBackupData(data);
    } catch {
      setError('Die Datei konnte nicht gelesen werden. Bitte eine gueltige JSON-Datei waehlen.');
      setBackupData(null);
    }
  };

  const handleRestore = async () => {
    if (!backupData) return;
    setRestoring(true);
    setError('');
    setRestoreResult(null);
    try {
      const result = await restoreBackup(backupData);
      setRestoreResult(result);
      setBackupData(null);
      setFileName('');
      if (fileInputRef.current) fileInputRef.current.value = '';
    } catch (err: any) {
      setError('Wiederherstellung fehlgeschlagen: ' + err.message);
    } finally {
      setRestoring(false);
    }
  };

  return (
    <div class="max-w-2xl">
      <h1 class="text-2xl font-bold text-[#0f0f0f] mb-6">Backup & Wiederherstellung</h1>

      {error && (
        <div class="bg-red-50 text-red-700 text-sm px-4 py-3 rounded-lg border border-red-200 mb-6">
          {error}
        </div>
      )}

      {/* Download */}
      <div class="bg-white rounded-xl border border-gray-200 p-6 mb-6">
        <h2 class="text-lg font-semibold text-[#0f0f0f] mb-2">Backup herunterladen</h2>
        <p class="text-sm text-gray-500 mb-4">
          Laden Sie eine vollstaendige Sicherung aller Daten herunter (Produkte, Kategorien, Bewertungen, Uebersetzungen, Einstellungen).
        </p>
        <button
          onClick={handleDownload}
          disabled={downloading}
          class="bg-[#D4A843] hover:bg-[#c49a3a] text-white font-semibold py-2.5 px-6 rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed text-sm flex items-center gap-2"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M7 10l5 5 5-5M12 15V3" />
          </svg>
          {downloading ? 'Wird heruntergeladen...' : 'Backup herunterladen'}
        </button>
      </div>

      {/* Restore */}
      <div class="bg-white rounded-xl border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-[#0f0f0f] mb-2">Backup wiederherstellen</h2>
        <p class="text-sm text-gray-500 mb-4">
          Stellen Sie Daten aus einer zuvor heruntergeladenen Backup-Datei wieder her.
          <strong class="text-red-600"> Achtung: Bestehende Daten werden ueberschrieben!</strong>
        </p>

        {/* File input */}
        <div class="mb-4">
          <label class="cursor-pointer inline-flex items-center gap-2 bg-gray-100 hover:bg-gray-200 text-sm font-medium px-4 py-2.5 rounded-lg transition-colors">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4M17 8l-5-5-5 5M12 3v12" />
            </svg>
            Datei waehlen
            <input
              ref={fileInputRef}
              type="file"
              accept=".json"
              onChange={handleFileSelect}
              class="hidden"
            />
          </label>
          {fileName && (
            <span class="ml-3 text-sm text-gray-600">{fileName}</span>
          )}
        </div>

        {/* Preview */}
        {backupData && (
          <div class="mb-4 p-4 bg-gray-50 rounded-lg border border-gray-100">
            <h3 class="text-sm font-semibold text-[#0f0f0f] mb-2">Vorschau:</h3>
            <ul class="text-sm text-gray-600 space-y-1">
              {Object.keys(backupData).map((key) => (
                <li key={key} class="flex items-center gap-2">
                  <span class="w-1.5 h-1.5 bg-[#D4A843] rounded-full shrink-0" />
                  <span class="font-medium">{key}</span>
                  <span class="text-gray-400">
                    {Array.isArray(backupData[key])
                      ? `(${backupData[key].length} Eintraege)`
                      : typeof backupData[key] === 'object'
                      ? `(${Object.keys(backupData[key]).length} Schluessel)`
                      : ''}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {backupData && (
          <button
            onClick={handleRestore}
            disabled={restoring}
            class="bg-[#a42325] hover:bg-[#8a1e20] text-white font-semibold py-2.5 px-6 rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed text-sm"
          >
            {restoring ? 'Wird wiederhergestellt...' : 'Wiederherstellen'}
          </button>
        )}

        {/* Result */}
        {restoreResult && (
          <div class="mt-4 p-4 bg-green-50 rounded-lg border border-green-200">
            <h3 class="text-sm font-semibold text-green-700 mb-2">Wiederherstellung erfolgreich!</h3>
            <p class="text-sm text-green-600">
              Wiederhergestellte Bereiche: {restoreResult.keys.join(', ')}
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
