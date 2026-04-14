# Project Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Scaffold the React frontend project with all dependencies, Tailwind + shadcn theming, folder structure, and base infrastructure files.

**Architecture:** Vite + React 18 SPA. Tailwind v4 with CSS-first config and class-based dark mode. shadcn/ui with custom green theme from Flutter project. Zustand for auth state, Axios with JWT interceptors, TanStack Query for server state.

**Tech Stack:** React 18, Vite, Tailwind CSS v4, shadcn/ui, Zustand, Axios, TanStack Query v5, React Hook Form, Zod, date-fns, sonner

---

### Task 1: Scaffold Vite + React project

**Files:**
- Create: entire project scaffolding in `LH_Gestion_Tarjas/` (Vite generates these)

**Note:** Since `LH_Gestion_Tarjas/` already contains `GESTION_TARJA_FRONTEND.md` and `docs/`, we scaffold Vite into a temp directory and move files into the existing root.

- [ ] **Step 1: Create Vite project in temp dir**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja"
npm create vite@latest lh-temp -- --template react
```

Expected: Project scaffolded in `lh-temp/` with `package.json`, `vite.config.js`, `src/`, `index.html`, etc.

- [ ] **Step 2: Move Vite files into existing project root**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja"
cp -r lh-temp/* LH_Gestion_Tarjas/
cp lh-temp/.gitignore LH_Gestion_Tarjas/
rm -rf lh-temp
```

- [ ] **Step 3: Install base dependencies**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
npm install
```

Expected: `node_modules/` created, `package-lock.json` generated.

- [ ] **Step 4: Verify dev server starts**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
npx vite --host 0.0.0.0 &
sleep 3
curl -s http://localhost:5173 | head -5
kill %1 2>/dev/null
```

Expected: HTML response containing `<div id="root">`.

---

### Task 2: Install all runtime and dev dependencies

**Files:**
- Modify: `package.json`

- [ ] **Step 1: Install runtime dependencies**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
npm install react-router-dom @tanstack/react-query zustand axios react-hook-form @hookform/resolvers zod date-fns sonner
```

- [ ] **Step 2: Install Tailwind CSS v4 dev dependencies**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
npm install -D tailwindcss @tailwindcss/vite
```

- [ ] **Step 3: Verify all packages in package.json**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
node -e "const p=require('./package.json'); const deps=Object.keys({...p.dependencies,...p.devDependencies}); ['react-router-dom','@tanstack/react-query','zustand','axios','react-hook-form','@hookform/resolvers','zod','date-fns','sonner','tailwindcss','@tailwindcss/vite'].forEach(d=>{if(!deps.includes(d))console.log('MISSING:',d);else console.log('OK:',d)})"
```

Expected: All packages show "OK".

---

### Task 3: Configure Tailwind v4 + dark mode + custom theme

**Files:**
- Modify: `vite.config.js` (add Tailwind plugin)
- Modify: `src/index.css` (Tailwind v4 CSS-first config with custom theme)
- Delete: `src/App.css` (not needed with Tailwind)

- [ ] **Step 1: Add Tailwind plugin to Vite config**

Replace `vite.config.js` with:

```js
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

- [ ] **Step 2: Configure Tailwind v4 with custom theme in `src/index.css`**

Replace `src/index.css` with:

```css
@import "tailwindcss";

@custom-variant dark (&:where(.dark, .dark *));

@theme {
  --color-primary: #2E7D32;
  --color-primary-light: #4CAF50;
  --color-primary-dark: #1B5E20;
  --color-accent: #66BB6A;

  --color-surface: #F8F9FA;
  --color-card: #FFFFFF;
  --color-text-primary: #212121;
  --color-text-secondary: #757575;

  --color-success: #4CAF50;
  --color-error: #F44336;
  --color-warning: #FF9800;
  --color-info: #2196F3;

  --color-sidebar: #1B5E20;
  --color-sidebar-foreground: #FFFFFF;
  --color-sidebar-accent: #2E7D32;

  --color-background: #FFFFFF;
  --color-foreground: #212121;
  --color-border: #E5E7EB;
  --color-input: #E5E7EB;
  --color-ring: #2E7D32;
  --color-muted: #F3F4F6;
  --color-muted-foreground: #757575;
  --color-destructive: #F44336;

  --radius-sm: 0.25rem;
  --radius-md: 0.375rem;
  --radius-lg: 0.5rem;
  --radius-xl: 0.75rem;
}

/*
  Dark mode overrides.
  Applied when <html class="dark"> is set.
*/
.dark {
  --color-surface: #121212;
  --color-card: #1E1E1E;
  --color-text-primary: #E0E0E0;
  --color-text-secondary: #9E9E9E;

  --color-background: #121212;
  --color-foreground: #E0E0E0;
  --color-border: #333333;
  --color-input: #333333;
  --color-ring: #4CAF50;
  --color-muted: #2D2D2D;
  --color-muted-foreground: #9E9E9E;

  --color-sidebar: #0D3B0F;
  --color-sidebar-foreground: #E0E0E0;
  --color-sidebar-accent: #1B5E20;
}

body {
  font-family: 'Inter', system-ui, -apple-system, sans-serif;
  background-color: var(--color-background);
  color: var(--color-foreground);
}
```

- [ ] **Step 3: Delete `src/App.css`**

```bash
rm "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas\src\App.css"
```

- [ ] **Step 4: Update `src/App.jsx` to verify Tailwind works**

Replace `src/App.jsx` with:

```jsx
const App = () => {
  return (
    <div className="min-h-screen bg-surface flex items-center justify-center">
      <div className="bg-card p-8 rounded-xl shadow-lg text-center">
        <h1 className="text-3xl font-bold text-primary mb-2">
          LH Gestion Tarjas
        </h1>
        <p className="text-text-secondary">
          Setup completo. Tailwind funcionando.
        </p>
      </div>
    </div>
  )
}

export default App
```

- [ ] **Step 5: Verify dev server renders with Tailwind styles**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
npx vite --host 0.0.0.0 &
sleep 3
curl -s http://localhost:5173 | head -10
kill %1 2>/dev/null
```

Expected: Page renders. Green-themed card visible in browser at `http://localhost:5173`.

---

### Task 4: Initialize shadcn/ui

**Files:**
- Create: `components.json`
- Create: `src/lib/utils.js` (shadcn generates this)
- Modify: `src/components/ui/` (shadcn components land here)

- [ ] **Step 1: Initialize shadcn**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
npx shadcn@latest init -d
```

The `-d` flag uses defaults. This creates `components.json` and `src/lib/utils.js` with the `cn()` helper.

If prompted interactively, select:
- Style: New York
- Base color: Neutral
- CSS variables: yes

- [ ] **Step 2: Verify `components.json` exists and `cn()` works**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
cat components.json
cat src/lib/utils.js
```

Expected: `components.json` with paths config. `src/lib/utils.js` exports `cn()` function using `clsx` + `tailwind-merge`.

- [ ] **Step 3: Install a test component to verify shadcn pipeline**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
npx shadcn@latest add button -y
```

Expected: `src/components/ui/button.jsx` created.

- [ ] **Step 4: Verify Button component imports correctly**

Update `src/App.jsx`:

```jsx
import { Button } from '@/components/ui/button'

const App = () => {
  return (
    <div className="min-h-screen bg-surface flex items-center justify-center">
      <div className="bg-card p-8 rounded-xl shadow-lg text-center space-y-4">
        <h1 className="text-3xl font-bold text-primary mb-2">
          LH Gestion Tarjas
        </h1>
        <p className="text-text-secondary">
          Setup completo. Tailwind + shadcn funcionando.
        </p>
        <Button className="bg-primary hover:bg-primary-dark text-white">
          Boton de prueba
        </Button>
      </div>
    </div>
  )
}

export default App
```

- [ ] **Step 5: Verify in dev server**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
npx vite --host 0.0.0.0 &
sleep 3
curl -s http://localhost:5173 | head -10
kill %1 2>/dev/null
```

Expected: Page renders with green Button component.

---

### Task 5: Create folder structure

**Files:**
- Create: `src/api/.gitkeep`
- Create: `src/components/layout/.gitkeep`
- Create: `src/components/shared/.gitkeep`
- Create: `src/pages/.gitkeep`
- Create: `src/hooks/.gitkeep`
- Create: `src/store/` (will have authStore.js in Task 6)

- [ ] **Step 1: Create all directories with .gitkeep files**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas\src"
mkdir -p api components/layout components/shared pages hooks store
touch api/.gitkeep components/layout/.gitkeep components/shared/.gitkeep pages/.gitkeep hooks/.gitkeep
```

- [ ] **Step 2: Verify structure**

```bash
find "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas\src" -type d | sort
```

Expected:
```
src/
src/api
src/components
src/components/layout
src/components/shared
src/components/ui
src/hooks
src/lib
src/pages
src/store
```

---

### Task 6: Create `store/authStore.js`

**Files:**
- Create: `src/store/authStore.js`

- [ ] **Step 1: Create the auth store**

Create `src/store/authStore.js`:

```js
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export const useAuthStore = create(
  persist(
    (set, get) => ({
      token: null,
      user: null,

      setAuth: (token, user) => set({ token, user }),

      logout: () => set({ token: null, user: null }),

      getSucursal: () => get().user?.sucursal,

      getRole: () => get().user?.role,

      getProfile: () => get().user?.profile,
    }),
    { name: 'lh-gestion-auth' }
  )
)
```

- [ ] **Step 2: Verify store imports without errors**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
node -e "import('./src/store/authStore.js').then(m => console.log('OK:', Object.keys(m))).catch(e => console.log('ERR:', e.message))"
```

Expected: `OK: [ 'useAuthStore' ]`

---

### Task 7: Create `lib/axios.js`

**Files:**
- Create: `src/lib/axios.js`

- [ ] **Step 1: Create Axios instance with interceptors**

Create `src/lib/axios.js`:

```js
import axios from 'axios'
import { useAuthStore } from '@/store/authStore'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
})

api.interceptors.request.use((config) => {
  const token = useAuthStore.getState().token
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      useAuthStore.getState().logout()
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default api
```

---

### Task 8: Create `lib/queryClient.js`

**Files:**
- Create: `src/lib/queryClient.js`

- [ ] **Step 1: Create QueryClient configuration**

Create `src/lib/queryClient.js`:

```js
import { QueryClient } from '@tanstack/react-query'

export const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5,
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
})
```

---

### Task 9: Add utility helpers to `lib/utils.js`

**Files:**
- Modify: `src/lib/utils.js` (shadcn already created this with `cn()`)

- [ ] **Step 1: Add format helpers to the existing utils file**

Append to `src/lib/utils.js` (keep the existing `cn` import and export):

```js
export const formatFecha = (isoString) =>
  new Date(isoString).toLocaleDateString('es-CL')

export const formatMoneda = (n) =>
  new Intl.NumberFormat('es-CL', {
    style: 'currency',
    currency: 'CLP',
  }).format(n)

export const formatRUT = (rut, dv) => {
  const r = rut.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
  return `${r}-${dv}`
}
```

- [ ] **Step 2: Verify helpers work**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
node -e "
const { formatRUT, formatMoneda } = await import('./src/lib/utils.js');
console.log('RUT:', formatRUT(12345678, 'K'));
console.log('Moneda:', formatMoneda(150000));
" 2>/dev/null || echo "Note: import.meta not available in Node, will verify in browser"
```

Expected: May fail due to `cn()` dependencies in Node context — that's fine. Verified in browser in next task.

---

### Task 10: Create environment files

**Files:**
- Create: `.env.local`
- Create: `.env.production`

- [ ] **Step 1: Create `.env.local`**

Create `.env.local`:

```
VITE_API_URL=http://localhost:8000
```

- [ ] **Step 2: Create `.env.production`**

Create `.env.production`:

```
VITE_API_URL=https://apilhtarja-927498545444.us-central1.run.app
```

- [ ] **Step 3: Verify `.gitignore` excludes `.env.local`**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
grep "env.local" .gitignore
```

Expected: `.env*.local` or `.env.local` in gitignore (Vite template includes this by default).

---

### Task 11: Wire up App entry point with providers

**Files:**
- Modify: `src/main.jsx`
- Modify: `src/App.jsx`

- [ ] **Step 1: Update `src/main.jsx` with QueryClientProvider**

Replace `src/main.jsx` with:

```jsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { QueryClientProvider } from '@tanstack/react-query'
import { queryClient } from '@/lib/queryClient'
import { Toaster } from 'sonner'
import App from './App'
import './index.css'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <App />
      <Toaster richColors position="top-right" />
    </QueryClientProvider>
  </StrictMode>
)
```

- [ ] **Step 2: Update `src/App.jsx` with final test content**

Replace `src/App.jsx` with:

```jsx
import { Button } from '@/components/ui/button'
import { useAuthStore } from '@/store/authStore'
import { toast } from 'sonner'

const App = () => {
  const user = useAuthStore((s) => s.user)

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center">
      <div className="bg-card p-8 rounded-xl shadow-lg text-center space-y-4">
        <h1 className="text-3xl font-bold text-primary">
          LH Gestion Tarjas
        </h1>
        <p className="text-text-secondary">
          Setup completo. Stack listo para desarrollo.
        </p>
        <div className="flex gap-2 justify-center">
          <Button
            className="bg-primary hover:bg-primary-dark text-white"
            onClick={() => toast.success('Toast funcionando')}
          >
            Test Toast
          </Button>
          <Button
            variant="outline"
            onClick={() => {
              document.documentElement.classList.toggle('dark')
            }}
          >
            Toggle Dark Mode
          </Button>
        </div>
        <p className="text-xs text-text-secondary">
          User: {user ? user.sub : 'No autenticado'} |
          API: {import.meta.env.VITE_API_URL}
        </p>
      </div>
    </div>
  )
}

export default App
```

- [ ] **Step 3: Verify everything works**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
npx vite --host 0.0.0.0 &
sleep 3
curl -s http://localhost:5173 | head -10
kill %1 2>/dev/null
```

Expected: Page renders with green theme, toast button works, dark mode toggle works, API URL shown.

---

### Task 12: Git init and initial commit

**Files:**
- Create: `.git/` (git init)

- [ ] **Step 1: Initialize git repository**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
git init
```

- [ ] **Step 2: Stage all files**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
git add .
git status
```

Expected: All project files staged. `node_modules/`, `.env.local`, `dist/` excluded by `.gitignore`.

- [ ] **Step 3: Create initial commit**

```bash
cd "C:\Users\migue\OneDrive\Documentos\Mis_Proyectos\LH_Tarja\LH_Gestion_Tarjas"
git commit -m "chore: initial project setup

Vite + React 18, Tailwind v4 with green theme (light/dark),
shadcn/ui, Zustand auth store, Axios with JWT interceptors,
TanStack Query, React Hook Form + Zod, date-fns, sonner.

Folder structure: api/, components/, pages/, hooks/, store/, lib/"
```

Expected: Commit created successfully.
