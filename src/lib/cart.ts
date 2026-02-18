export interface CartItem {
  id: string;
  variantId: string;
  title: string;
  variantTitle: string;
  price: number;
  quantity: number;
  image?: string;
}

export interface Cart {
  items: CartItem[];
}

const CART_KEY = 'beefactory-cart';

export function getCart(): Cart {
  if (typeof window === 'undefined') return { items: [] };
  try {
    const stored = localStorage.getItem(CART_KEY);
    return stored ? JSON.parse(stored) : { items: [] };
  } catch {
    return { items: [] };
  }
}

export function saveCart(cart: Cart): void {
  if (typeof window === 'undefined') return;
  localStorage.setItem(CART_KEY, JSON.stringify(cart));
  window.dispatchEvent(new CustomEvent('cart-updated', { detail: cart }));
}

export function addToCart(item: Omit<CartItem, 'quantity'>, quantity = 1): Cart {
  const cart = getCart();
  const existing = cart.items.find((i) => i.variantId === item.variantId);
  if (existing) {
    existing.quantity += quantity;
  } else {
    cart.items.push({ ...item, quantity });
  }
  saveCart(cart);
  return cart;
}

export function removeFromCart(variantId: string): Cart {
  const cart = getCart();
  cart.items = cart.items.filter((i) => i.variantId !== variantId);
  saveCart(cart);
  return cart;
}

export function updateQuantity(variantId: string, quantity: number): Cart {
  const cart = getCart();
  const item = cart.items.find((i) => i.variantId === variantId);
  if (item) {
    if (quantity <= 0) {
      return removeFromCart(variantId);
    }
    item.quantity = quantity;
  }
  saveCart(cart);
  return cart;
}

export function getCartTotal(cart: Cart): number {
  return cart.items.reduce((sum, item) => sum + item.price * item.quantity, 0);
}

export function getCartCount(cart: Cart): number {
  return cart.items.reduce((sum, item) => sum + item.quantity, 0);
}

export function clearCart(): Cart {
  const cart = { items: [] };
  saveCart(cart);
  return cart;
}
