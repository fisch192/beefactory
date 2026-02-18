// Shopify Storefront API — Phase 2 implementation
import type { Product, ProductVariant } from '../data/products';
import type { Collection } from '../data/collections';

const DOMAIN = import.meta.env.PUBLIC_SHOPIFY_STORE_DOMAIN ?? '';
const TOKEN = import.meta.env.PUBLIC_SHOPIFY_STOREFRONT_TOKEN ?? '';
const API_VERSION = '2024-10';

export function isShopifyConfigured(): boolean {
  return !!(DOMAIN && TOKEN);
}

// ── Base GraphQL client ──────────────────────────────────────────────────────

async function shopifyFetch<T>(
  query: string,
  variables?: Record<string, unknown>,
  langCode: 'DE' | 'IT' = 'DE',
): Promise<T | null> {
  if (!isShopifyConfigured()) return null;
  try {
    const res = await fetch(
      `https://${DOMAIN}/api/${API_VERSION}/graphql.json`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Storefront-Access-Token': TOKEN,
          'Accept-Language': langCode === 'IT' ? 'it' : 'de',
        },
        body: JSON.stringify({ query, variables }),
      },
    );
    if (!res.ok) {
      console.error(`Shopify API error: ${res.status} ${res.statusText}`);
      return null;
    }
    const json = await res.json();
    if (json.errors?.length) {
      console.error('Shopify GraphQL errors:', json.errors);
      return null;
    }
    return json.data as T;
  } catch (e) {
    console.error('Shopify fetch error:', e);
    return null;
  }
}

// ── GraphQL fragments ────────────────────────────────────────────────────────

const PRODUCT_FIELDS = `
  id
  handle
  title
  description(truncateAt: 600)
  tags
  featuredImage { url }
  images(first: 8) { edges { node { url altText } } }
  priceRange { minVariantPrice { amount currencyCode } }
  compareAtPriceRange { minVariantPrice { amount } }
  collections(first: 3) { edges { node { handle } } }
  variants(first: 20) {
    edges {
      node {
        id
        title
        price { amount }
        compareAtPrice { amount }
        availableForSale
      }
    }
  }
`;

const COLLECTION_FIELDS = `
  id
  handle
  title
  description(truncateAt: 400)
  image { url }
`;

// ── Type mappers ─────────────────────────────────────────────────────────────

interface ShopifyVariantNode {
  id: string;
  title: string;
  price: { amount: string };
  compareAtPrice?: { amount: string } | null;
  availableForSale: boolean;
}

interface ShopifyProductNode {
  id: string;
  handle: string;
  title: string;
  description: string;
  tags: string[];
  featuredImage?: { url: string } | null;
  images: { edges: { node: { url: string; altText?: string } }[] };
  priceRange: { minVariantPrice: { amount: string; currencyCode: string } };
  compareAtPriceRange: { minVariantPrice: { amount: string } };
  collections: { edges: { node: { handle: string } }[] };
  variants: { edges: { node: ShopifyVariantNode }[] };
}

interface ShopifyCollectionNode {
  id: string;
  handle: string;
  title: string;
  description: string;
  image?: { url: string } | null;
  products?: { edges: { node: ShopifyProductNode }[] };
}

function mapVariant(v: ShopifyVariantNode): ProductVariant {
  return {
    id: v.id, // real Shopify GID: gid://shopify/ProductVariant/...
    title: v.title,
    price: parseFloat(v.price.amount),
    compareAtPrice: v.compareAtPrice ? parseFloat(v.compareAtPrice.amount) : undefined,
    available: v.availableForSale,
  };
}

function mapProduct(
  node: ShopifyProductNode,
  titleDe: string,
  titleIt: string,
  descDe: string,
  descIt: string,
): Product {
  const variants = node.variants.edges.map((e) => mapVariant(e.node));
  const firstVariant = variants[0];
  const images = node.images.edges.map((e) => e.node.url);
  const collection = node.collections.edges[0]?.node.handle ?? '';

  return {
    id: node.id,
    handle: node.handle,
    title: { de: titleDe, it: titleIt },
    description: { de: descDe, it: descIt },
    price: firstVariant?.price ?? parseFloat(node.priceRange.minVariantPrice.amount),
    compareAtPrice: firstVariant?.compareAtPrice,
    images,
    collection,
    variants,
    tags: node.tags,
    featured: node.tags.includes('featured') || node.tags.includes('bestseller'),
  };
}

function mapCollection(
  node: ShopifyCollectionNode,
  titleDe: string,
  titleIt: string,
  descDe: string,
  descIt: string,
): Collection {
  return {
    id: node.id,
    handle: node.handle,
    title: { de: titleDe, it: titleIt },
    description: { de: descDe, it: descIt },
    image: node.image?.url,
  };
}

// ── Products ─────────────────────────────────────────────────────────────────

interface ProductsResponse {
  products: { edges: { node: ShopifyProductNode }[] };
}

async function fetchProductsForLang(
  lang: 'DE' | 'IT',
  first = 250,
): Promise<ShopifyProductNode[] | null> {
  const data = await shopifyFetch<ProductsResponse>(
    `query GetProducts($first: Int!) @inContext(language: ${lang}) {
       products(first: $first, sortKey: CREATED_AT) {
         edges { node { ${PRODUCT_FIELDS} } }
       }
     }`,
    { first },
    lang,
  );
  return data?.products.edges.map((e) => e.node) ?? null;
}

export async function getAllShopifyProducts(): Promise<Product[] | null> {
  if (!isShopifyConfigured()) return null;

  const [de, it] = await Promise.all([
    fetchProductsForLang('DE'),
    fetchProductsForLang('IT'),
  ]);
  if (!de) return null;

  return de.map((deNode, i) => {
    const itNode = it?.[i] ?? deNode;
    return mapProduct(deNode, deNode.title, itNode.title, deNode.description, itNode.description);
  });
}

interface SingleProductResponse {
  productByHandle: ShopifyProductNode | null;
}

export async function getShopifyProductByHandle(handle: string): Promise<Product | null> {
  if (!isShopifyConfigured()) return null;

  const [deData, itData] = await Promise.all([
    shopifyFetch<SingleProductResponse>(
      `query GetProduct($handle: String!) @inContext(language: DE) {
         productByHandle(handle: $handle) { ${PRODUCT_FIELDS} }
       }`,
      { handle },
      'DE',
    ),
    shopifyFetch<SingleProductResponse>(
      `query GetProduct($handle: String!) @inContext(language: IT) {
         productByHandle(handle: $handle) { ${PRODUCT_FIELDS} }
       }`,
      { handle },
      'IT',
    ),
  ]);

  const deNode = deData?.productByHandle;
  if (!deNode) return null;
  const itNode = itData?.productByHandle ?? deNode;

  return mapProduct(deNode, deNode.title, itNode.title, deNode.description, itNode.description);
}

// ── Collections ──────────────────────────────────────────────────────────────

interface CollectionsResponse {
  collections: { edges: { node: ShopifyCollectionNode }[] };
}

async function fetchCollectionsForLang(
  lang: 'DE' | 'IT',
  first = 50,
): Promise<ShopifyCollectionNode[] | null> {
  const data = await shopifyFetch<CollectionsResponse>(
    `query GetCollections($first: Int!) @inContext(language: ${lang}) {
       collections(first: $first) {
         edges { node { ${COLLECTION_FIELDS} } }
       }
     }`,
    { first },
    lang,
  );
  return data?.collections.edges.map((e) => e.node) ?? null;
}

export async function getAllShopifyCollections(): Promise<Collection[] | null> {
  if (!isShopifyConfigured()) return null;

  const [de, it] = await Promise.all([
    fetchCollectionsForLang('DE'),
    fetchCollectionsForLang('IT'),
  ]);
  if (!de) return null;

  return de.map((deNode, i) => {
    const itNode = it?.[i] ?? deNode;
    return mapCollection(
      deNode,
      deNode.title,
      itNode.title,
      deNode.description,
      itNode.description,
    );
  });
}

interface CollectionWithProductsResponse {
  collectionByHandle: (ShopifyCollectionNode & {
    products: { edges: { node: ShopifyProductNode }[] };
  }) | null;
}

export async function getShopifyCollectionByHandle(
  handle: string,
): Promise<{ collection: Collection; products: Product[] } | null> {
  if (!isShopifyConfigured()) return null;

  const query = (lang: string) => `
    query GetCollection($handle: String!) @inContext(language: ${lang}) {
      collectionByHandle(handle: $handle) {
        ${COLLECTION_FIELDS}
        products(first: 50, sortKey: CREATED_AT) {
          edges { node { ${PRODUCT_FIELDS} } }
        }
      }
    }`;

  const [deData, itData] = await Promise.all([
    shopifyFetch<CollectionWithProductsResponse>(query('DE'), { handle }, 'DE'),
    shopifyFetch<CollectionWithProductsResponse>(query('IT'), { handle }, 'IT'),
  ]);

  const deNode = deData?.collectionByHandle;
  if (!deNode) return null;
  const itNode = itData?.collectionByHandle ?? deNode;

  const collection = mapCollection(
    deNode,
    deNode.title,
    itNode.title,
    deNode.description,
    itNode.description,
  );

  const deProducts = deNode.products.edges.map((e) => e.node);
  const itProducts = itNode.products?.edges.map((e) => e.node) ?? deProducts;

  const products = deProducts.map((deP, i) => {
    const itP = itProducts[i] ?? deP;
    return mapProduct(deP, deP.title, itP.title, deP.description, itP.description);
  });

  return { collection, products };
}

// ── Cart / Checkout ───────────────────────────────────────────────────────────

interface CartCreateResponse {
  cartCreate: {
    cart: { id: string; checkoutUrl: string } | null;
    userErrors: { field: string[]; message: string }[];
  };
}

/**
 * Creates a Shopify cart with the given line items and returns the checkout URL.
 * variantId must be a valid Shopify GID: gid://shopify/ProductVariant/...
 */
export async function createShopifyCheckout(
  lines: { variantId: string; quantity: number }[],
): Promise<string | null> {
  if (!isShopifyConfigured()) return null;

  const data = await shopifyFetch<CartCreateResponse>(
    `mutation CartCreate($input: CartInput!) {
       cartCreate(input: $input) {
         cart { id checkoutUrl }
         userErrors { field message }
       }
     }`,
    {
      input: {
        lines: lines.map((l) => ({ merchandiseId: l.variantId, quantity: l.quantity })),
      },
    },
  );

  if (data?.cartCreate?.userErrors?.length) {
    console.error('Shopify cart errors:', data.cartCreate.userErrors);
  }

  return data?.cartCreate?.cart?.checkoutUrl ?? null;
}

/** Whether a variantId looks like a real Shopify GID (not a mock ID) */
export function isShopifyGid(id: string): boolean {
  return id.startsWith('gid://shopify/');
}
