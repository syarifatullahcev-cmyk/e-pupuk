import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// https://vite.dev/config/
// VITE_BACKEND_URL: http://127.0.0.1:8000 (lokal) | http://backend:8000 (Docker)
const backendUrl = process.env.VITE_BACKEND_URL || 'http://127.0.0.1:8000';

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

