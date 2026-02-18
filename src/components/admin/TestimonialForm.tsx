import { h } from 'preact';
import { useState } from 'preact/hooks';
import FormField from './FormField';

interface TestimonialFormProps {
  testimonial?: any;
  onSave: (data: any) => void;
  onCancel: () => void;
}

export default function TestimonialForm({ testimonial, onSave, onCancel }: TestimonialFormProps) {
  const [name, setName] = useState(testimonial?.name ?? '');
  const [location, setLocation] = useState(testimonial?.location ?? testimonial?.ort ?? '');
  const [textDe, setTextDe] = useState(testimonial?.text?.de ?? testimonial?.textDe ?? '');
  const [textIt, setTextIt] = useState(testimonial?.text?.it ?? testimonial?.textIt ?? '');
  const [rating, setRating] = useState<number>(testimonial?.rating ?? 5);
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (e: Event) => {
    e.preventDefault();
    setSaving(true);
    try {
      const data = {
        name,
        location,
        text: { de: textDe, it: textIt },
        rating: Number(rating),
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
      <div class="grid grid-cols-2 gap-4">
        <FormField label="Name" value={name} onChange={setName} required placeholder="Max Mustermann" />
        <FormField label="Ort" value={location} onChange={setLocation} placeholder="Bozen, Suedtirol" />
      </div>

      <FormField label="Text (Deutsch)" type="textarea" value={textDe} onChange={setTextDe} required rows={4} placeholder="Bewertungstext..." />
      <FormField label="Text (Italiano)" type="textarea" value={textIt} onChange={setTextIt} rows={4} placeholder="Testo della recensione..." />

      {/* Star rating */}
      <div class="space-y-1">
        <label class="block text-sm font-medium text-[#0f0f0f]">
          Bewertung
        </label>
        <div class="flex items-center gap-1">
          {[1, 2, 3, 4, 5].map((star) => (
            <button
              key={star}
              type="button"
              onClick={() => setRating(star)}
              class={`text-2xl transition-colors ${
                star <= rating ? 'text-[#D4A843]' : 'text-gray-300'
              } hover:text-[#D4A843]`}
              aria-label={`${star} Stern${star > 1 ? 'e' : ''}`}
            >
              &#9733;
            </button>
          ))}
          <span class="ml-2 text-sm text-gray-500">{rating} / 5</span>
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
