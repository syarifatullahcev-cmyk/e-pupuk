import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
// VITE_BACKEND_URL: https://e-pupuk.vercel.app (Cloud Vercel + TiDB Cloud)
const rawBackendUrl = process.env.VITE_BACKEND_URL || 'https://e-pupuk.vercel.app';
const backendUrl = rawBackendUrl.includes('backend:') ? 'https://e-pupuk.vercel.app' : rawBackendUrl;

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],
  server: {
    port: 5173,
    host: '0.0.0.0',   // Diperlukan agar Vite bisa diakses dari luar container
    proxy: {
      '/api': {
        target: backendUrl,
        changeOrigin: true,
      },
      '/files': {
        target: backendUrl,
        changeOrigin: true,
      },
    },
  },
})

