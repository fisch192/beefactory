import { useState, useEffect } from 'preact/hooks';
import { getCart, removeFromCart, updateQuantity, getCartTotal, getCartCount } from '../../lib/cart';
import type { Cart } from '../../lib/cart';
import { createShopifyCheckout, isShopifyGid } from '../../lib/shopify';

interface Props {
  title: string;
  emptyText: string;
  totalText: string;
  checkoutText: string;
  continueText: string;
  removeText: string;
}

export default function CartDrawer({ title, emptyText, totalText, checkoutText, continueText, removeText }: Props) {
  const [cart, setCart] = useState<Cart>({ items: [] });
  const [isOpen, setIsOpen] = useState(false);
  const [isCheckingOut, setIsCheckingOut] = useState(false);

  useEffect(() => {
    setCart(getCart());

    const onCartUpdate = (e: Event) => {
      const detail = (e as CustomEvent).detail;
      if (detail) setCart(detail);
    };
    const onOpenCart = () => setIsOpen(true);

    window.addEventListener('cart-updated', onCartUpdate);
    window.addEventListener('open-cart', onOpenCart);

    // Also listen for header cart button click
    document.getElementById('cart-toggle')?.addEventListener('click', onOpenCart);

    return () => {
      window.removeEventListener('cart-updated', onCartUpdate);
      window.removeEventListener('open-cart', onOpenCart);
    };
  }, []);

  const handleRemove = (variantId: string) => {
    const updated = removeFromCart(variantId);
    setCart(updated);
  };

  const handleUpdateQty = (variantId: string, qty: number) => {
    const updated = updateQuantity(variantId, qty);
    setCart(updated);
  };

  const total = getCartTotal(cart);
  const count = getCartCount(cart);

  const handleCheckout = async () => {
    setIsCheckingOut(true);
    try {
      const lines = cart.items.map((item) => ({
        variantId: item.variantId,
        quantity: item.quantity,
      }));
      if (lines.every((l) => isShopifyGid(l.variantId))) {
        const url = await createShopifyCheckout(lines);
        if (url) {
          window.location.href = url;
          return;
        }
      }
      // Fallback: go to Shopify store homepage
      const domain = import.meta.env.PUBLIC_SHOPIFY_STORE_DOMAIN;
      if (domain) window.location.href = `https://${domain}`;
    } finally {
      setIsCheckingOut(false);
    }
  };

  const formatPrice = (price: number) =>
    new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(price);

  if (!isOpen) return null;

  return (
    <div class="fixed inset-0 z-[200]">
      {/* Backdrop */}
      <div class="absolute inset-0 bg-black/50" onClick={() => setIsOpen(false)} />

      {/* Drawer */}
      <div class="absolute top-0 right-0 h-full w-full max-w-md bg-off-white shadow-2xl flex flex-col">
        {/* Header */}
        <div class="flex items-center justify-between p-5 border-b border-black/10">
          <h2 class="font-semibold text-lg">{title} ({count})</h2>
          <button
            onClick={() => setIsOpen(false)}
            class="p-1 text-mid-gray hover:text-near-black transition-colors"
            aria-label="Close"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round">
              <line x1="18" y1="6" x2="6" y2="18" />
              <line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>

        {/* Items */}
        <div class="flex-1 overflow-y-auto p-5">
          {cart.items.length === 0 ? (
            <div class="flex flex-col items-center justify-center h-full text-mid-gray">
              <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" class="mb-4 opacity-40">
                <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" />
                <line x1="3" y1="6" x2="21" y2="6" />
                <path d="M16 10a4 4 0 01-8 0" />
              </svg>
              <p>{emptyText}</p>
            </div>
          ) : (
            <div class="space-y-4">
              {cart.items.map((item) => (
                <div key={item.variantId} class="flex gap-4 p-4 bg-white">
                  {/* Placeholder */}
                  <div class="w-16 h-16 shrink-0 bg-warm-gray honeycomb-bg" />

                  <div class="flex-1 min-w-0">
                    <h3 class="font-medium text-sm truncate">{item.title}</h3>
                    {item.variantTitle !== 'Standard' && (
                      <p class="text-xs text-mid-gray">{item.variantTitle}</p>
                    )}
                    <p class="text-sm font-semibold mt-1">{formatPrice(item.price)}</p>

                    <div class="flex items-center justify-between mt-2">
                      <div class="flex items-center border border-black/10">
                        <button
                          onClick={() => handleUpdateQty(item.variantId, item.quantity - 1)}
                          class="w-8 h-8 flex items-center justify-center text-mid-gray hover:text-near-black transition-colors"
                        >
                          -
                        </button>
                        <span class="w-8 h-8 flex items-center justify-center text-sm font-medium">
                          {item.quantity}
                        </span>
                        <button
                          onClick={() => handleUpdateQty(item.variantId, item.quantity + 1)}
                          class="w-8 h-8 flex items-center justify-center text-mid-gray hover:text-near-black transition-colors"
                        >
                          +
                        </button>
                      </div>
                      <button
                        onClick={() => handleRemove(item.variantId)}
                        class="text-xs text-mid-gray hover:text-burgundy transition-colors"
                      >
                        {removeText}
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Footer */}
        {cart.items.length > 0 && (
          <div class="p-5 border-t border-black/10 space-y-4">
            <div class="flex items-center justify-between font-semibold text-lg">
              <span>{totalText}</span>
              <span>{formatPrice(total)}</span>
            </div>
            <button
              onClick={handleCheckout}
              disabled={isCheckingOut}
              class="w-full py-4 bg-burgundy text-white font-semibold hover:bg-burgundy-dark transition-colors disabled:opacity-60 disabled:cursor-not-allowed"
            >
              {isCheckingOut ? '...' : checkoutText}
            </button>
            <button
              onClick={() => setIsOpen(false)}
              class="w-full text-center text-sm text-mid-gray hover:text-near-black transition-colors"
            >
              {continueText}
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
