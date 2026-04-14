# LH Gestion Tarjas — Project Setup (Paso 1)

Setup inicial del proyecto React: scaffolding, dependencias, configuracion de tema, estructura de carpetas y archivos base de infraestructura. No incluye paginas ni componentes de UI.

---

## 1. Scaffolding

- Crear proyecto con `npm create vite@latest` usando template `react` (JavaScript)
- El proyecto se crea dentro de `LH_Gestion_Tarjas/` como carpeta raiz del frontend

## 2. Dependencias

### Runtime
| Paquete | Version | Proposito |
|---------|---------|-----------|
| react-router-dom | ^6 | Navegacion SPA |
| @tanstack/react-query | ^5 | Fetching, cache, mutations |
| zustand | ^5 | Estado global (sesion, usuario) |
| axios | ^1 | Cliente HTTP con interceptor JWT |
| react-hook-form | ^7 | Formularios |
| @hookform/resolvers | ^3 | Integracion Zod con RHF |
| zod | ^3 | Validacion de schemas |
| date-fns | ^4 | Manejo de fechas (Chile dd/MM/yyyy) |
| sonner | ^1 | Toast notifications |

### Dev
| Paquete | Proposito |
|---------|-----------|
| tailwindcss | ^4 | Estilos utilitarios |
| @tailwindcss/vite | Plugin Vite para Tailwind v4 |

shadcn/ui se inicializa con `npx shadcn@latest init` despues de Tailwind.

## 3. Tailwind + Dark Mode

Tailwind v4 usa CSS-first configuration. Se configura dark mode via `class` strategy para toggle manual.

### Paleta de colores (del proyecto Flutter)

```
Primary:        #2E7D32 (verde oscuro)
Primary Light:  #4CAF50 (verde medio)
Primary Dark:   #1B5E20 (verde muy oscuro)
Accent:         #66BB6A (verde claro)
Surface:        #F8F9FA (gris muy claro)
Card:           #FFFFFF
Text Primary:   #212121
Text Secondary: #757575
Success:        #4CAF50
Error:          #F44336
Warning:        #FF9800
Info:           #2196F3
```

shadcn/ui se configura con estos colores como CSS variables en el tema custom. Se definen variables para light y dark.

## 4. Estructura de carpetas

```
src/
  api/           → funciones de llamada a la API (vacio por ahora)
  components/
    ui/          → componentes shadcn
    layout/      → Sidebar, Header, AppLayout (vacios por ahora)
    shared/      → DataTable, StatusBadge, etc. (vacios por ahora)
  pages/         → paginas por modulo (vacias por ahora)
  hooks/         → hooks custom (vacios por ahora)
  store/
    authStore.js → store Zustand con persist para JWT + usuario
  lib/
    axios.js     → instancia Axios con interceptores JWT + 401
    queryClient.js → configuracion TanStack Query
    utils.js     → formatRUT, formatFecha, formatMoneda
```

## 5. Archivos base implementados

### `store/authStore.js`
Store Zustand con `persist` middleware. Campos: `token`, `user` (sub, role, profile, sucursal). Metodos: `setAuth`, `logout`, `getSucursal`, `getRole`, `getProfile`.

### `lib/axios.js`
Instancia Axios con:
- `baseURL` desde `import.meta.env.VITE_API_URL`
- Interceptor request: agrega `Authorization: Bearer <token>` si existe
- Interceptor response: en 401, ejecuta `logout()` y redirige a `/login`

### `lib/queryClient.js`
QueryClient con defaults razonables (staleTime, retry).

### `lib/utils.js`
Helpers: `formatFecha` (es-CL), `formatMoneda` (CLP), `formatRUT(rut, dv)`, mas `cn()` helper de shadcn para clases condicionales.

### `.env.local`
```
VITE_API_URL=http://localhost:8000
```

### `.env.production`
```
VITE_API_URL=https://apilhtarja-927498545444.us-central1.run.app
```

## 6. Git

- `git init` en la carpeta del proyecto
- `.gitignore` generado por Vite (incluye node_modules, dist, .env.local)
- Commit inicial con todo el setup

## 7. Fuera de scope

- Paginas (login, dashboard, revision, etc.)
- Componentes compartidos (DataTable, StatusBadge, etc.)
- Layout (Sidebar, Header, AppLayout)
- Rutas (react-router config)
- Estos se implementan en pasos siguientes
