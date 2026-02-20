# 09. The Design-to-Code Translator
**Role:** Design Engineer at Vercel + Frontend Design Expert
**Brand:** Beefactory

## Objective
Convert the "Industrial Organic" (Figma Prototype 05) into production-ready frontend specifications using React and Tailwind CSS. Reject all standard Tailwind defaults (no `rounded-md`, no generic shadows).

---

## 1. COMPONENT ARCHITECTURE (The Engineering Hub)

### Component: `EngineeredButton.tsx`
- **Props Interface:**
  ```typescript
  interface EngineeredButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
    variant?: 'primary' | 'secondary' | 'ghost';
    size?: 'sm' | 'md' | 'lg';
    isLoading?: boolean;
    icon?: React.ReactNode;
    children: React.ReactNode;
  }
  ```
- **State:** Internally uses `framer-motion` for interaction physics rather than standard CSS transitions.

## 2. PRODUCTION CODE (Tailwind Implementation)

```tsx
import { motion } from 'framer-motion';
import clsx from 'clsx';
import { twMerge } from 'tailwind-merge';

export const EngineeredButton = ({
  variant = 'primary',
  size = 'md',
  isLoading = false,
  icon,
  children,
  className,
  ...props
}: EngineeredButtonProps) => {
  const baseClasses = "relative inline-flex items-center justify-center font-mono uppercase tracking-widest transition-colors duration-300 focus:outline-none focus:ring-2 focus:ring-amber-500 focus:ring-offset-4 focus:ring-offset-black disabled:opacity-50 disabled:cursor-not-allowed rounded-none";
  
  const variants = {
    primary: "bg-[#FFB400] text-[#0A0A0A] hover:bg-[#CC9000]",
    secondary: "bg-transparent text-[#F5F5F7] border border-[#F5F5F7] hover:bg-[#1C1C1E]",
    ghost: "bg-transparent text-[#FFB400] underline decoration-transparent hover:decoration-[#FFB400] underline-offset-4"
  };

  const sizes = {
    sm: "h-8 px-4 text-xs",
    md: "h-12 px-8 text-sm",
    lg: "h-16 px-12 text-base"
  };

  return (
    <motion.button
      whileHover={variant !== 'ghost' ? { y: -2 } : {}}
      whileTap={variant !== 'ghost' ? { y: 0, scale: 0.98 } : {}}
      transition={{ type: "spring", stiffness: 400, damping: 25 }}
      className={twMerge(clsx(baseClasses, variants[variant], sizes[size]), className)}
      disabled={isLoading || props.disabled}
      {...props}
    >
      {isLoading ? (
        <span className="absolute inset-0 flex items-center justify-center">
          <LoadingSpinner className="w-5 h-5 text-current" />
        </span>
      ) : null}
      <span className={clsx("flex items-center gap-3", isLoading && "opacity-0")}>
        {icon}
        {children}
      </span>
    </motion.button>
  );
};
```

## 3. DESIGN TOKEN INTEGRATION (`tailwind.config.js`)

```javascript
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        void: "#0A0A0A",
        machined: "#1C1C1E",
        amber: {
          500: "#FFB400", // Raw Amber
          600: "#CC9000", // Burnt Gold
        },
        titanium: "#F5F5F7",
        steel: "#8E8E93",
        hazard: "#FF453A",
      },
      fontFamily: {
        display: ['var(--font-ogg)', 'serif'],
        mono: ['var(--font-jetbrains)', 'monospace'],
      },
      boxShadow: {
        // We reject soft, blurry shadows. We use hard, structural highlights.
        'machined-edge': 'inset 0 1px 0 0 rgba(255, 255, 255, 0.04)',
      },
      transitionTimingFunction: {
        'industrial-snap': 'cubic-bezier(0.16, 1, 0.3, 1)',
      }
    },
  },
  plugins: [],
}
```

## 4. ASSET OPTIMIZATION
- **Images:** All hero imagery (`.webp` or `.avif`) loaded via Next.js `<Image />` component with `priority` flags. The rest are lazy-loaded. 
- **Typography:** `Ogg` and `JetBrains Mono` are self-hosted via `next/font/local` to eliminate layout shift (CLS) and FOIT.

---
**Designer's Intent:** Notice the explicit `rounded-none` in the button classes. Tailwind usually defaults to 4px (`rounded`). We disable this to force the harsh geometry. We also use Framer Motion for the `:active`/`:hover` states because CSS transitions are too smooth—we need the spring physics to make the button feel like flipping a physical steel switch.
