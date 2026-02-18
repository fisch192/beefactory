import { h } from 'preact';
import { useState, useEffect } from 'preact/hooks';
import FormField from './FormField';
import { uploadImage } from '../../lib/admin-api';

interface Variant {
  title: string;
  price: number | '';
  available: boolean;
}

interface ProductFormProps {
  product?: any;
  collections?: any[];
  onSave: (data: any) => void;
  onCancel: () => void;
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[aeoeue]/g, (m: string) => ({ ae: 'ae', oe: 'oe', ue: 'ue' }[m] || m))
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

export default function ProductForm({ product, collections = [], onSave, onCancel }: ProductFormProps) {
  const [handle, setHandle] = useState(product?.handle ?? '');
  const [titleDe, setTitleDe] = useState(product?.title?.de ?? product?.titleDe ?? '');
  const [titleIt, setTitleIt] = useState(product?.title?.it ?? product?.titleIt ?? '');
  const [descDe, setDescDe] = useState(product?.description?.de ?? product?.descriptionDe ?? '');
  const [descIt, setDescIt] = useState(product?.description?.it ?? product?.descriptionIt ?? '');
  const [price, setPrice] = useState<number | ''>(product?.price ?? '');
  const [comparePrice, setComparePrice] = useState<number | ''>(product?.compareAtPrice ?? product?.comparePrice ?? '');
  const [collection, setCollection] = useState(product?.collection ?? product?.collectionHandle ?? '');
  const [tags, setTags] = useState(product?.tags?.join?.(', ') ?? product?.tags ?? '');
  const [featured, setFeatured] = useState(product?.featured ?? false);
  const [images, setImages] = useState<string[]>(product?.images ?? []);
  const [variants, setVariants] = useState<Variant[]>(
    product?.variants ?? [{ title: '', price: '', available: true }]
  );
  const [uploading, setUploading] = useState(false);
  const [saving, setSaving] = useState(false);

  // Auto-generate handle from German title
  useEffect(() => {
    if (!product && titleDe) {
      setHandle(slugify(titleDe));
    }
  }, [titleDe, product]);

  const handleImageUpload = async (e: Event) => {
    const input = e.target as HTMLInputElement;
    if (!input.files?.length) return;
    setUploading(true);
    try {
      const file = input.files[0];
      const result = await uploadImage(file);
      setImages([...images, result.url]);
    } catch (err) {
      alert('Bild-Upload fehlgeschlagen.');
    } finally {
      setUploading(false);
      input.value = '';
    }
  };

  const removeImage = (index: number) => {
    setImages(images.filter((_, i) => i !== index));
  };

  const addVariant = () => {
    setVariants([...variants, { title: '', price: '', available: true }]);
  };

  const updateVariant = (index: number, field: keyof Variant, value: any) => {
    const updated = [...variants];
    updated[index] = { ...updated[index], [field]: value };
    setVariants(updated);
  };

  const removeVariant = (index: number) => {
    setVariants(variants.filter((_, i) => i !== index));
  };

  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    setSaving(true);
    try {
      const data: any = {
        handle,
        title: { de: titleDe, it: titleIt },
        description: { de: descDe, it: descIt },
        price: typeof price === 'number' ? price : parseFloat(String(price)),
        images,
        featured,
        tags: tags
          .split(',')
          .map((t: string) => t.trim())
          .filter(Boolean),
        variants: variants.map((v) => ({
          title: v.title,
          price: typeof v.price === 'number' ? v.price : parseFloat(String(v.price)) || 0,
          available: v.available,
        })),
      };
      if (comparePrice !== '' && comparePrice !== undefined) {
        data.compareAtPrice = typeof comparePrice === 'number' ? comparePrice : parseFloat(String(comparePrice));
      }
      if (collection) {
        data.collection = collection;
      }
      await onSave(data);
    } catch {
      // handled by parent
    } finally {
      setSaving(false);
    }
  };

  return (
    <form onSubmit={handleSubmit} class="space-y-5">
      <FormField label="Handle" value={handle} onChange={setHandle} required placeholder="produkt-handle" />

      <div class="grid grid-cols-2 gap-4">
        <FormField label="Titel (Deutsch)" value={titleDe} onChange={setTitleDe} required placeholder="Produktname" />
        <FormField label="Titel (Italiano)" value={titleIt} onChange={setTitleIt} placeholder="Nome prodotto" />
      </div>

      <div class="grid grid-cols-2 gap-4">
        <FormField label="Beschreibung (Deutsch)" type="textarea" value={descDe} onChange={setDescDe} rows={4} />
        <FormField label="Beschreibung (Italiano)" type="textarea" value={descIt} onChange={setDescIt} rows={4} />
      </div>

      <div class="grid grid-cols-2 gap-4">
        <FormField label="Preis (EUR)" type="number" value={price} onChange={setPrice} required step={0.01} min={0} />
        <FormField label="Vergleichspreis (EUR)" type="number" value={comparePrice} onChange={setComparePrice} step={0.01} min={0} placeholder="Optional" />
      </div>

      <div class="space-y-1">
        <label class="block text-sm font-medium text-[#0f0f0f]">Kategorie</label>
        <select
          value={collection}
          onChange={(e) => setCollection((e.target as HTMLSelectElement).value)}
          class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm text-[#0f0f0f] focus:border-[#D4A843] focus:ring-2 focus:ring-[#D4A843]/20 focus:outline-none transition-colors"
        >
          <option value="">-- Keine Kategorie --</option>
          {collections.map((c) => (
            <option key={c.handle || c.id} value={c.handle || c.id}>
              {c.title?.de || c.titleDe || c.handle || c.id}
            </option>
          ))}
        </select>
      </div>

      <FormField label="Tags (kommagetrennt)" value={tags} onChange={setTags} placeholder="honig, bio, geschenk" />

      <FormField label="Featured" type="checkbox" value={featured} onChange={setFeatured} />

      {/* Images */}
      <div class="space-y-2">
        <label class="block text-sm font-medium text-[#0f0f0f]">Bilder</label>
        {images.length > 0 && (
          <div class="flex flex-wrap gap-2">
            {images.map((url, i) => (
              <div key={i} class="relative group">
                <img src={url} alt="" class="w-20 h-20 object-cover rounded-lg border border-gray-200" />
                <button
                  type="button"
                  onClick={() => removeImage(i)}
                  class="absolute -top-2 -right-2 bg-red-500 text-white rounded-full w-5 h-5 flex items-center justify-center text-xs opacity-0 group-hover:opacity-100 transition-opacity"
                >
                  x
                </button>
              </div>
            ))}
          </div>
        )}
        <div class="flex items-center gap-2">
          <label class="cursor-pointer bg-gray-100 hover:bg-gray-200 text-sm font-medium px-4 py-2 rounded-lg transition-colors">
            {uploading ? 'Wird hochgeladen...' : 'Bild hochladen'}
            <input type="file" accept="image/*" onChange={handleImageUpload} class="hidden" disabled={uploading} />
          </label>
        </div>
      </div>

      {/* Variants */}
      <div class="space-y-3">
        <div class="flex items-center justify-between">
          <label class="block text-sm font-medium text-[#0f0f0f]">Varianten</label>
          <button
            type="button"
            onClick={addVariant}
            class="text-sm text-[#D4A843] hover:text-[#c49a3a] font-medium"
          >
            + Variante hinzufuegen
          </button>
        </div>
        {variants.map((v, i) => (
          <div key={i} class="flex items-start gap-3 p-3 bg-gray-50 rounded-lg border border-gray-100">
            <div class="flex-1 grid grid-cols-2 gap-3">
              <input
                type="text"
                value={v.title}
                onInput={(e) => updateVariant(i, 'title', (e.target as HTMLInputElement).value)}
                placeholder="Titel"
                class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-[#D4A843] focus:ring-2 focus:ring-[#D4A843]/20 focus:outline-none"
              />
              <input
                type="number"
                value={v.price}
                onInput={(e) => {
                  const val = (e.target as HTMLInputElement).value;
                  updateVariant(i, 'price', val === '' ? '' : Number(val));
                }}
                placeholder="Preis"
                step="0.01"
                min="0"
                class="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-[#D4A843] focus:ring-2 focus:ring-[#D4A843]/20 focus:outline-none"
              />
            </div>
            <label class="flex items-center gap-1.5 pt-2 cursor-pointer select-none">
              <input
                type="checkbox"
                checked={v.available}
                onChange={(e) => updateVariant(i, 'available', (e.target as HTMLInputElement).checked)}
                class="h-4 w-4 rounded border-gray-300 text-[#D4A843]"
              />
              <span class="text-xs text-gray-600">Verfuegbar</span>
            </label>
            {variants.length > 1 && (
              <button
                type="button"
                onClick={() => removeVariant(i)}
                class="text-red-400 hover:text-red-600 pt-2"
                title="Variante entfernen"
              >
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                  <path d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            )}
          </div>
        ))}
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
