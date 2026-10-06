import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// The React app talks to the Spring Boot backend through this proxy, so the browser only ever sees one origin.
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: true,
    proxy: {
      '/api': 'http://localhost:8080',
      '/images': 'http://localhost:8080',
    },
  },
})
