// @ts-check
import { defineConfig } from 'astro/config';
import preact from '@astrojs/preact';
import tailwindcss from '@tailwindcss/vite';
import sitemap from '@astrojs/sitemap';
import vercel from '@astrojs/vercel';

export default defineConfig({
  site: 'https://beefactory.shop',
  output: 'server',
  integrations: [preact(), sitemap()],
  vite: {
    plugins: [tailwindcss()]
  },
  adapter: vercel()
});
