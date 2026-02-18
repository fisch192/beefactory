import { getAllShopifyProducts, getShopifyProductByHandle } from '../lib/shopify';
import { getStore } from '../lib/store';

export interface ProductVariant {
  id: string;
  title: string;
  price: number;
  compareAtPrice?: number;
  available: boolean;
}

export interface Product {
  id: string;
  handle: string;
  title: Record<string, string>;
  description: Record<string, string>;
  price: number;
  compareAtPrice?: number;
  images: string[];
  collection: string;
  variants: ProductVariant[];
  tags: string[];
  featured?: boolean;
}

// ── Static fallback data ─────────────────────────────────────────────────────

const staticProducts: Product[] = [
  {
    id: 'starterset-dadant',
    handle: 'starterset-dadant',
    title: { de: 'Starterset Dadant', it: 'Set Iniziale Dadant' },
    description: {
      de: 'Alles was Sie als Neuimker für den Start mit dem Dadant-System benötigen. Enthält Beute, Rähmchen, Smoker, Stockmeißel und Schutzausrüstung.',
      it: 'Tutto ciò di cui hai bisogno come nuovo apicoltore per iniziare con il sistema Dadant. Include arnia, telai, affumicatore, leva e attrezzatura protettiva.',
    },
    price: 330,
    images: [],
    collection: 'startersets',
    variants: [{ id: 'sd-standard', title: 'Standard', price: 330, available: true }],
    tags: ['neuimker', 'bestseller'],
    featured: true,
  },
  {
    id: 'starterset-zander',
    handle: 'starterset-zander',
    title: { de: 'Starterset Zander', it: 'Set Iniziale Zander' },
    description: {
      de: 'Das komplette Starterpaket für das bewährte Zander-System. Perfekt für Anfänger und empfohlen von erfahrenen Imkern.',
      it: 'Il pacchetto iniziale completo per il collaudato sistema Zander. Perfetto per principianti e raccomandato da apicoltori esperti.',
    },
    price: 330,
    images: [],
    collection: 'startersets',
    variants: [{ id: 'sz-standard', title: 'Standard', price: 330, available: true }],
    tags: ['neuimker', 'bestseller'],
    featured: true,
  },
  {
    id: 'smoker-edelstahl',
    handle: 'smoker-edelstahl',
    title: { de: 'Smoker Edelstahl', it: 'Affumicatore Acciaio Inox' },
    description: {
      de: 'Hochwertiger Edelstahl-Smoker mit Lederschutz und optimaler Rauchentwicklung.',
      it: 'Affumicatore in acciaio inox di alta qualità con protezione in pelle e sviluppo ottimale del fumo.',
    },
    price: 39.9,
    images: [],
    collection: 'werkzeuge-smoker',
    variants: [{ id: 'sm-standard', title: 'Standard', price: 39.9, available: true }],
    tags: ['werkzeug'],
  },
  {
    id: 'stockmeissel-profi',
    handle: 'stockmeissel-profi',
    title: { de: 'Stockmeißel Profi', it: 'Leva Professionale' },
    description: {
      de: 'Professioneller Stockmeißel aus gehärtetem Edelstahl. Unverzichtbares Werkzeug für jeden Imker.',
      it: 'Leva professionale in acciaio inox temperato. Strumento indispensabile per ogni apicoltore.',
    },
    price: 12.9,
    images: [],
    collection: 'werkzeuge-smoker',
    variants: [{ id: 'sp-standard', title: 'Standard', price: 12.9, available: true }],
    tags: ['werkzeug'],
  },
  {
    id: 'imkeranzug-premium',
    handle: 'imkeranzug-premium',
    title: { de: 'Imkeranzug Premium', it: 'Tuta Apicoltore Premium' },
    description: {
      de: 'Belüfteter Ganzkörper-Imkeranzug mit Rundschleier. Hochwertiges Material, waschbar und extra bequem.',
      it: 'Tuta apicoltore ventilata integrale con velo rotondo. Materiale di alta qualità, lavabile e molto comoda.',
    },
    price: 89.9,
    images: [],
    collection: 'schutz-kleidung',
    variants: [
      { id: 'ia-m', title: 'M', price: 89.9, available: true },
      { id: 'ia-l', title: 'L', price: 89.9, available: true },
      { id: 'ia-xl', title: 'XL', price: 89.9, available: true },
    ],
    tags: ['schutz'],
  },
  {
    id: 'imkerhandschuhe-leder',
    handle: 'imkerhandschuhe-leder',
    title: { de: 'Imkerhandschuhe Leder', it: 'Guanti Apicoltore in Pelle' },
    description: {
      de: 'Langstulpen-Handschuhe aus weichem Ziegenleder mit Baumwoll-Ärmeln.',
      it: 'Guanti a manopola in morbida pelle di capra con maniche in cotone.',
    },
    price: 24.9,
    images: [],
    collection: 'schutz-kleidung',
    variants: [
      { id: 'ih-m', title: 'M', price: 24.9, available: true },
      { id: 'ih-l', title: 'L', price: 24.9, available: true },
    ],
    tags: ['schutz'],
  },
  {
    id: 'honigschleuder-4-waben',
    handle: 'honigschleuder-4-waben',
    title: { de: 'Honigschleuder 4 Waben', it: 'Smielatore 4 Telai' },
    description: {
      de: 'Tangential-Honigschleuder aus Edelstahl für 4 Waben. Handkurbel, stabile Konstruktion.',
      it: 'Smielatore tangenziale in acciaio inox per 4 telai. Manovella a mano, costruzione stabile.',
    },
    price: 189,
    images: [],
    collection: 'honigernte-verarbeitung',
    variants: [{ id: 'hs-standard', title: 'Standard', price: 189, available: true }],
    tags: ['honigernte'],
  },
  {
    id: 'entdeckelungsgabel',
    handle: 'entdeckelungsgabel',
    title: { de: 'Entdeckelungsgabel', it: 'Forchetta per Disopercolare' },
    description: {
      de: 'Edelstahl-Entdeckelungsgabel mit ergonomischem Griff.',
      it: 'Forchetta per disopercolare in acciaio inox con impugnatura ergonomica.',
    },
    price: 8.9,
    images: [],
    collection: 'honigernte-verarbeitung',
    variants: [{ id: 'eg-standard', title: 'Standard', price: 8.9, available: true }],
    tags: ['honigernte'],
  },
  {
    id: 'dadant-beute-komplett',
    handle: 'dadant-beute-komplett',
    title: { de: 'Dadant Beute Komplett', it: 'Arnia Dadant Completa' },
    description: {
      de: 'Komplette Dadant-Beute aus hochwertigem Holz. Inkl. Boden, Brutraum, Honigraum, Deckel und Rähmchen.',
      it: 'Arnia Dadant completa in legno di alta qualità. Incl. fondo, nido, melario, coperchio e telai.',
    },
    price: 149,
    images: [],
    collection: 'bienenbeuten-zubehoer',
    variants: [{ id: 'db-standard', title: 'Standard', price: 149, available: true }],
    tags: ['beute'],
  },
  {
    id: 'zander-beute-komplett',
    handle: 'zander-beute-komplett',
    title: { de: 'Zander Beute Komplett', it: 'Arnia Zander Completa' },
    description: {
      de: 'Komplette Zander-Beute aus imprägniertem Holz. Inkl. Boden, Brutraum, Honigraum und Deckel.',
      it: 'Arnia Zander completa in legno impregnato. Incl. fondo, nido, melario e coperchio.',
    },
    price: 139,
    images: [],
    collection: 'bienenbeuten-zubehoer',
    variants: [{ id: 'zb-standard', title: 'Standard', price: 139, available: true }],
    tags: ['beute'],
  },
  {
    id: 'futtertrog-10l',
    handle: 'futtertrog-10l',
    title: { de: 'Futtertrog 10L', it: 'Nutritore 10L' },
    description: {
      de: '10-Liter-Futtertrog für die Herbst- und Notfütterung.',
      it: "Nutritore da 10 litri per l'alimentazione autunnale e d'emergenza.",
    },
    price: 14.9,
    images: [],
    collection: 'fuetterung-gesundheit',
    variants: [{ id: 'ft-standard', title: 'Standard', price: 14.9, available: true }],
    tags: ['fütterung'],
  },
  {
    id: 'oxalsaeure-verdampfer',
    handle: 'oxalsaeure-verdampfer',
    title: { de: 'Oxalsäure-Verdampfer', it: 'Evaporatore Acido Ossalico' },
    description: {
      de: 'Elektrischer Oxalsäure-Verdampfer zur Varroa-Behandlung.',
      it: 'Evaporatore elettrico di acido ossalico per il trattamento della varroa.',
    },
    price: 59.9,
    images: [],
    collection: 'fuetterung-gesundheit',
    variants: [{ id: 'ov-standard', title: 'Standard', price: 59.9, available: true }],
    tags: ['gesundheit', 'varroa'],
  },
];

// ── Async API-backed getters (try Shopify → fallback to static) ──────────────

/** Fetch all products. Store → Shopify → static fallback. */
export async function getProducts(): Promise<Product[]> {
  try {
    const store = await getStore();
    const stored = await store.get<Product[]>('products');
    if (stored && stored.length > 0) return stored;
  } catch { /* fall through */ }

  const shopify = await getAllShopifyProducts();
  return shopify ?? staticProducts;
}

/** Fetch a single product by handle. Store → Shopify → static fallback. */
export async function getProduct(handle: string): Promise<Product | undefined> {
  try {
    const store = await getStore();
    const stored = await store.get<Product[]>('products');
    if (stored) {
      const found = stored.find((p) => p.handle === handle);
      if (found) return found;
    }
  } catch { /* fall through */ }

  const shopify = await getShopifyProductByHandle(handle);
  if (shopify) return shopify;
  return staticProducts.find((p) => p.handle === handle);
}

/** Fetch featured products (tagged 'featured' or 'bestseller'). */
export async function getFeaturedProductsAsync(): Promise<Product[]> {
  const all = await getProducts();
  return all.filter((p) => p.featured || p.tags.includes('bestseller'));
}

/** Fetch products belonging to a collection. */
export async function getProductsByCollectionAsync(collectionHandle: string): Promise<Product[]> {
  const all = await getProducts();
  return all.filter((p) => p.collection === collectionHandle);
}

// ── Legacy sync helpers (static data only, for backward compat) ──────────────

export const products = staticProducts;

export function getProductByHandle(handle: string): Product | undefined {
  return staticProducts.find((p) => p.handle === handle);
}

export function getProductsByCollection(collectionHandle: string): Product[] {
  return staticProducts.filter((p) => p.collection === collectionHandle);
}

export function getFeaturedProducts(): Product[] {
  return staticProducts.filter((p) => p.featured);
}
