import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import FormField from './FormField';
import { uploadImage } from '../../lib/admin-api';

interface CollectionFormProps {
  collection?: any;
  onSave: (data: any) => void;
  onCancel: () => void;
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

export default function CollectionForm({ collection, onSave, onCancel }: CollectionFormProps) {
  const [handle, setHandle] = useState(collection?.handle ?? '');
  const [titleDe, setTitleDe] = useState(collection?.title?.de ?? collection?.titleDe ?? '');
  const [titleIt, setTitleIt] = useState(collection?.title?.it ?? collection?.titleIt ?? '');
  const [descDe, setDescDe] = useState(collection?.description?.de ?? collection?.descriptionDe ?? '');
  const [descIt, setDescIt] = useState(collection?.description?.it ?? collection?.descriptionIt ?? '');
  const [image, setImage] = useState(collection?.image ?? '');
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!collection && titleDe) {
      setHandle(slugify(titleDe));
    }
  }, [titleDe, collection]);

  const handleImageUpload = async (e: Event) => {
    const input = e.target as HTMLInputElement;
    if (!input.files?.length) return;
    setUploading(true);
    try {
      const file = input.files[0];
      const result = await uploadImage(file);
      setImage(result.url);
    } catch {
      alert('Bild-Upload fehlgeschlagen.');
    } finally {
      setUploading(false);
      input.value = '';
    }
  };

  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    setSaving(true);
    try {
      const data = {
        handle,
        title: { de: titleDe, it: titleIt },
        description: { de: descDe, it: descIt },
        image,
      };
      await onSave(data);
    } catch {
      // handled by parent
    } finally {
      setSaving(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} class="space-y-5">
      <FormField label="Handle" value={handle} onChange={setHandle} required placeholder="kategorie-handle" />

      <div class="grid grid-cols-2 gap-4">
        <FormField label="Titel (Deutsch)" value={titleDe} onChange={setTitleDe} required placeholder="Kategoriename" />
        <FormField label="Titel (Italiano)" value={titleIt} onChange={setTitleIt} placeholder="Nome categoria" />
      </div>

      <div class="grid grid-cols-2 gap-4">
        <FormField label="Beschreibung (Deutsch)" type="textarea" value={descDe} onChange={setDescDe} rows={4} />
        <FormField label="Beschreibung (Italiano)" type="textarea" value={descIt} onChange={setDescIt} rows={4} />
      </div>

      {/* Image */}
      <div class="space-y-2">
        <label class="block text-sm font-medium text-[#0f0f0f]">Bild</label>
        {image && (
          <div class="relative inline-block group">
            <img src={image} alt="" class="w-32 h-24 object-cover rounded-lg border border-gray-200" />
            <button
              type="button"
              onClick={() => setImage('')}
              class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs opacity-0 group-hover:opacity-100 transition-opacity"
            >
              x
            </button>
          </div>
        )}
        <div class="flex items-center gap-3">
          <label class="cursor-pointer bg-gray-100 hover:bg-gray-200 text-sm font-medium px-4 py-2 rounded-lg transition-colors">
            {uploading ? 'Wird hochgeladen...' : 'Bild hochladen'}
            <input type="file" accept="image/*" onChange={handleImageUpload} class="hidden" disabled={uploading} />
          </label>
          <span class="text-xs text-gray-400">oder</span>
          <input
            type="text"
            value={image}
            onInput={(e) => setImage((e.target as HTMLInputElement).value)}
            placeholder="Bild-URL eingeben"
            class="flex-1 rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-[#D4A843] focus:ring-2 focus:ring-[#D4A843]/20 focus:outline-none"
          />
        </div>
      </div>

      {/* Actions */}
      <div class="flex items-center justify-end gap-3 pt-4 border-t border-gray-200">
        <button
          type="button"
          onClick={onCancel}
          class="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-800 transition-colors"
        >
          Abbrechen
        </button>
        <button
          type="submit"
          disabled={saving}
          class="bg-[#D4A843] hover:bg-[#c49a3a] text-white font-semibold py-2 px-6 rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed text-sm"
        >
          {saving ? 'Wird gespeichert...' : 'Speichern'}
        </button>
      </div>
    </form>
  );
}
