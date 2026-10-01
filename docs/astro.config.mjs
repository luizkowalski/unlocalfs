import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';

export default defineConfig({
  site: 'https://unlocalfs.luizkowalski.net',
  integrations: [
    starlight({
      title: 'UnlocalFS',
      logo: { src: '../assets/logo.png' },
      favicon: '/favicon.png',
      social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/luizkowalski/unlocalfs' }],
      sidebar: [
        { label: 'Start here', items: [
          { label: 'Overview', slug: '' },
          { label: 'Getting started', slug: 'getting-started' },
        ] },
        { label: 'Settings', items: [
          { label: 'Connection', slug: 'connection-settings' },
          { label: 'Drive', slug: 'drive-settings' },
        ] },
        { label: 'Guides', items: [
          { label: 'Using drives', slug: 'using-drives' },
          { label: 'Folder drives', slug: 'folder-drives' },
          { label: 'Encryption', slug: 'encryption' },
          { label: 'Sharing links', slug: 'sharing-links' },
          { label: 'Troubleshooting', slug: 'troubleshooting' },
          { label: 'Privacy', slug: 'privacy' },
        ] },
      ],
    }),
  ],
});
