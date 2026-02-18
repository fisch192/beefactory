import { getStore } from '../lib/store';

export interface Testimonial {
  name: string;
  location: string;
  text: Record<string, string>;
  rating: number;
}

const staticTestimonials: Testimonial[] = [
  {
    name: 'Thomas M.',
    location: 'Bozen, Südtirol',
    text: {
      de: 'Als Anfänger war das Starterset genau richtig. Alles dabei, super Qualität und die Beratung war erstklassig!',
      it: "Come principiante il set iniziale era perfetto. Tutto incluso, qualità eccellente e la consulenza è stata di prima classe!",
    },
    rating: 5,
  },
  {
    name: 'Maria K.',
    location: 'Meran, Südtirol',
    text: {
      de: 'Endlich ein Shop der versteht, was Imker brauchen. Schnelle Lieferung und faire Preise. Komme immer wieder.',
      it: 'Finalmente un negozio che capisce cosa serve agli apicoltori. Consegna veloce e prezzi giusti. Torno sempre.',
    },
    rating: 5,
  },
  {
    name: 'Hans R.',
    location: 'Innsbruck, Tirol',
    text: {
      de: 'Die Qualität der Werkzeuge ist hervorragend. Mein Smoker hält jetzt schon 3 Jahre und funktioniert einwandfrei.',
      it: 'La qualità degli attrezzi è eccellente. Il mio affumicatore dura già da 3 anni e funziona perfettamente.',
    },
    rating: 5,
  },
  {
    name: 'Luisa B.',
    location: 'Brixen, Südtirol',
    text: {
      de: 'Toller Service! Bei Fragen bekomme ich immer schnell kompetente Antworten. Empfehle ich jedem Imker.',
      it: 'Servizio fantastico! Quando ho domande ricevo sempre risposte competenti e veloci. Lo consiglio a ogni apicoltore.',
    },
    rating: 5,
  },
];

// ── Async store-backed getter ─────────────────────────────────────────────────

/** Fetch all testimonials. Store → static fallback. */
export async function getTestimonials(): Promise<Testimonial[]> {
  try {
    const store = await getStore();
    const stored = await store.get<Testimonial[]>('testimonials');
    if (stored && stored.length > 0) return stored;
  } catch { /* fall through */ }
  return staticTestimonials;
}

// Legacy sync export
export const testimonials = staticTestimonials;
