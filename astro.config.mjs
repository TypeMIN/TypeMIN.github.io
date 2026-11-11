import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  site: 'https://typemin.github.io',
  output: 'static',
  trailingSlash: 'always',
  integrations: [sitemap()],
});
