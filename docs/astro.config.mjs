import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

export default defineConfig({
  site: "https://unlocalfs.luizkowalski.net",
  integrations: [
    starlight({
      title: "UnlocalFS",
      logo: { light: "../assets/logo.png", dark: "../assets/logo-dark.png" },
      favicon: "/favicon.png",
      head: [
        {
          tag: "script",
          attrs: {
            defer: true,
            src: "https://msg.sumiu.link/script.js",
            "data-website-id": "5afa2d49-baad-4aff-b53a-3f572bc3039f",
          },
        },
      ],
      social: [{ icon: "github", label: "GitHub", href: "https://github.com/luizkowalski/unlocalfs" }],
      sidebar: [
        {
          label: "Start here",
          items: [
            { label: "Overview", slug: "" },
            { label: "Getting started", slug: "getting-started" },
          ],
        },
        {
          label: "Settings",
          items: [
            { label: "Connection", slug: "connection-settings" },
            { label: "Drive", slug: "drive-settings" },
          ],
        },
        {
          label: "Guides",
          items: [
            { label: "Using drives", slug: "using-drives" },
            { label: "Google Cloud Storage", slug: "google-cloud-storage" },
            { label: "Google Drive", slug: "google-drive" },
            { label: "Folder drives", slug: "folder-drives" },
            { label: "Encryption", slug: "encryption" },
            { label: "Sharing links", slug: "sharing-links" },
            { label: "Duplicating files", slug: "duplicating-files" },
            { label: "File versions", slug: "file-versions" },
            { label: "Traffic", slug: "traffic" },
            { label: "Troubleshooting", slug: "troubleshooting" },
            { label: "Privacy", slug: "privacy" },
            { label: "Terms", slug: "terms" },
          ],
        },
      ],
    }),
  ],
});
