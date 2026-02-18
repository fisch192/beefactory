import { createContext } from 'preact';
import { useState, useEffect, useContext, useCallback } from 'preact/hooks';
import type { Cart, CartItem } from '../../lib/cart';
import { getCart, addToCart as addToCartFn, removeFromCart as removeFromCartFn, updateQuantity as updateQuantityFn, getCartTotal, getCartCount } from '../../lib/cart';

interface CartContextType {
  cart: Cart;
  addItem: (item: Omit<CartItem, 'quantity'>, qty?: number) => void;
  removeItem: (variantId: string) => void;
  updateQty: (variantId: string, qty: number) => void;
  total: number;
  count: number;
  isOpen: boolean;
  setIsOpen: (open: boolean) => void;
}

const CartContext = createContext<CartContextType | null>(null);

export function CartProvider({ children }: { children: preact.ComponentChildren }) {
  const [cart, setCart] = useState<Cart>({ items: [] });
  const [isOpen, setIsOpen] = useState(false);

  useEffect(() => {
    setCart(getCart());

    const handler = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      if (detail) setCart(detail);
    };
    window.addEventListener('cart-updated', handler);
    return () => window.removeEventListener('cart-updated', handler);
  }, []);

  const addItem = useCallback((item: Omit<CartItem, 'quantity'>, qty = 1) => {
    const updated = addToCartFn(item, qty);
    setCart(updated);
    setIsOpen(true);
  }, []);

  const removeItem = useCallback((variantId: string) => {
    const updated = removeFromCartFn(variantId);
    setCart(updated);
  }, []);

  const updateQty = useCallback((variantId: string, qty: number) => {
    const updated = updateQuantityFn(variantId, qty);
    setCart(updated);
  }, []);

  return (
    <CartContext.Provider
      value={{
        cart,
        addItem,
        removeItem,
        updateQty,
        total: getCartTotal(cart),
        count: getCartCount(cart),
        isOpen,
        setIsOpen,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error('useCart must be used within CartProvider');
  return ctx;
}
