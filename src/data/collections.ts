import { getAllShopifyCollections, getShopifyCollectionByHandle } from '../lib/shopify';
import { getStore } from '../lib/store';
import type { Product } from './products';

export interface Collection {
  id: string;
  handle: string;
  title: Record<string, string>;
  description: Record<string, string>;
  image?: string;
}

// ── Static fallback data ─────────────────────────────────────────────────────

const staticCollections: Collection[] = [
  {
    id: 'startersets',
    handle: 'startersets',
    title: { de: 'Startersets', it: 'Set Iniziali' },
    description: {
      de: 'Komplette Startersets für den Einstieg in die Imkerei. Alles in einem Paket.',
      it: "Set iniziali completi per iniziare l'apicoltura. Tutto in un unico pacchetto.",
    },
    image: '/images/cat-startersets.jpg',
  },
  {
    id: 'bienenbeuten-zubehoer',
    handle: 'bienenbeuten-zubehoer',
    title: { de: 'Bienenbeuten & Zubehör', it: 'Arnie & Accessori' },
    description: {
      de: 'Hochwertige Bienenbeuten und passendes Zubehör für alle gängigen Systeme.',
      it: 'Arnie di alta qualità e accessori adatti per tutti i sistemi comuni.',
    },
    image: '/images/cat-bienenbeuten.jpg',
  },
  {
    id: 'werkzeuge-smoker',
    handle: 'werkzeuge-smoker',
    title: { de: 'Werkzeuge & Smoker', it: 'Attrezzi & Affumicatori' },
    description: {
      de: 'Professionelle Imkerwerkzeuge und Smoker für die tägliche Arbeit am Bienenstock.',
      it: "Attrezzi professionali per l'apicoltura e affumicatori per il lavoro quotidiano all'alveare.",
    },
    image: '/images/cat-werkzeuge.jpg',
  },
  {
    id: 'schutz-kleidung',
    handle: 'schutz-kleidung',
    title: { de: 'Schutz & Kleidung', it: 'Protezione & Abbigliamento' },
    description: {
      de: 'Imkeranzüge, Handschuhe und Schutzkleidung für sicheres Arbeiten.',
      it: 'Tute, guanti e abbigliamento protettivo per lavorare in sicurezza.',
    },
    image: '/images/cat-schutz.jpg',
  },
  {
    id: 'honigernte-verarbeitung',
    handle: 'honigernte-verarbeitung',
    title: { de: 'Honigernte & Verarbeitung', it: 'Raccolta & Lavorazione Miele' },
    description: {
      de: 'Honigschleudern, Entdeckelungswerkzeuge und alles für die Honigernte.',
      it: 'Smielatori, attrezzi per disopercolare e tutto per la raccolta del miele.',
    },
    image: '/images/cat-honigernte.jpg',
  },
  {
    id: 'fuetterung-gesundheit',
    handle: 'fuetterung-gesundheit',
    title: { de: 'Fütterung & Gesundheit', it: 'Alimentazione & Salute' },
    description: {
      de: 'Futtertröge, Varroa-Behandlung und Gesundheitsprodukte für Ihre Bienenvölker.',
      it: 'Nutritori, trattamento varroa e prodotti per la salute delle tue colonie.',
    },
    image: '/images/cat-fuetterung.jpg',
  },
];

// ── Async API-backed getters ─────────────────────────────────────────────────

/** Fetch all collections. Store → Shopify → static fallback. */
export async function getCollections(): Promise<Collection[]> {
  try {
    const store = await getStore();
    const stored = await store.get<Collection[]>('collections');
    if (stored && stored.length > 0) return stored;
  } catch { /* fall through */ }

  const shopify = await getAllShopifyCollections();
  return shopify ?? staticCollections;
}

/** Fetch a single collection by handle, optionally with its products. Store → Shopify → static fallback. */
export async function getCollection(
  handle: string,
): Promise<{ collection: Collection; products: Product[] } | undefined> {
  try {
    const store = await getStore();
    const stored = await store.get<Collection[]>('collections');
    if (stored) {
      const found = stored.find((c) => c.handle === handle);
      if (found) {
        const { getProductsByCollectionAsync } = await import('./products');
        return { collection: found, products: await getProductsByCollectionAsync(handle) };
      }
    }
  } catch { /* fall through */ }

  const shopify = await getShopifyCollectionByHandle(handle);
  if (shopify) return shopify;

  // Static fallback — products imported lazily to avoid circular dep
  const { getProductsByCollection } = await import('./products');
  const collection = staticCollections.find((c) => c.handle === handle);
  if (!collection) return undefined;
  return { collection, products: getProductsByCollection(handle) };
}

// ── Legacy sync helpers (static data only) ───────────────────────────────────

export const collections = staticCollections;

export function getCollectionByHandle(handle: string): Collection | undefined {
  return staticCollections.find((c) => c.handle === handle);
}
