import { useState } from 'preact/hooks';
import { addToCart } from '../../lib/cart';

interface Props {
  productId: string;
  productTitle: string;
  variants: { id: string; title: string; price: number; available: boolean }[];
  buttonText: string;
  outOfStockText: string;
  variantLabel?: string;
}

export default function AddToCart({ productId, productTitle, variants, buttonText, outOfStockText, variantLabel }: Props) {
  const [selectedVariant, setSelectedVariant] = useState(variants[0]);
  const [adding, setAdding] = useState(false);

  const handleAdd = () => {
    if (!selectedVariant?.available) return;
    setAdding(true);
    addToCart({
      id: productId,
      variantId: selectedVariant.id,
      title: productTitle,
      variantTitle: selectedVariant.title,
      price: selectedVariant.price,
    });
    // Open cart drawer
    window.dispatchEvent(new CustomEvent('open-cart'));
    setTimeout(() => setAdding(false), 300);
  };

  return (
    <div class="space-y-4">
      {variants.length > 1 && (
        <div>
          {variantLabel && <label class="block text-sm font-medium mb-2">{variantLabel}</label>}
          <div class="flex flex-wrap gap-2">
            {variants.map((v) => (
              <button
                key={v.id}
                onClick={() => setSelectedVariant(v)}
                class={`px-4 py-2 text-sm border transition-colors ${
                  selectedVariant?.id === v.id
                    ? 'border-near-black bg-near-black text-white'
                    : 'border-black/20 hover:border-near-black'
                } ${!v.available ? 'opacity-40 cursor-not-allowed line-through' : ''}`}
                disabled={!v.available}
              >
                {v.title}
              </button>
            ))}
          </div>
        </div>
      )}

      <button
        onClick={handleAdd}
        disabled={!selectedVariant?.available || adding}
        class={`w-full py-4 font-semibold text-base transition-all duration-200 ${
          selectedVariant?.available
            ? 'bg-burgundy text-white hover:bg-burgundy-dark hover:scale-[1.02] active:scale-100'
            : 'bg-black/10 text-mid-gray cursor-not-allowed'
        }`}
      >
        {selectedVariant?.available ? (adding ? '...' : buttonText) : outOfStockText}
      </button>
    </div>
  );
}
