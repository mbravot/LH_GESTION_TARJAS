# LH Gestión Tarja — Contexto frontend (React)

App web de gestión para La Hornilla. Consume la API FastAPI existente.
Lee este documento completo antes de crear cualquier componente o página.

---

## Stack tecnológico

```
React 18+
React Router v6          → navegación SPA
TanStack Query v5        → fetching, caché, mutations (react-query)
Axios                    → cliente HTTP con interceptor JWT
Zustand                  → estado global (sesión, usuario activo)
Tailwind CSS             → estilos utilitarios
shadcn/ui                → componentes base (usa Tailwind por debajo)
React Hook Form + Zod    → formularios con validación
date-fns                 → manejo de fechas (Chile usa dd/MM/yyyy)
```

---

## Estructura de carpetas

```
src/
  api/                   → funciones de llamada a la API (una por módulo)
    auth.js
    revision.js
    aprobacion.js
    configuracion.js
    maestros.js
    rrhh.js
    reportes.js

  components/            → componentes reutilizables
    ui/                  → botones, inputs, badges, modales (shadcn wrapeados)
    layout/
      Sidebar.jsx        → navegación lateral por módulo
      Header.jsx         → usuario activo, sucursal activa, logout
      AppLayout.jsx      → wrapper general con sidebar + header
    shared/
      DataTable.jsx      → tabla con paginación, sort, filtro server-side
      StatusBadge.jsx    → badge de estado de actividad con colores
      ConfirmDialog.jsx  → modal de confirmación para acciones destructivas
      PageHeader.jsx     → título de página + botón de acción principal

  pages/                 → una carpeta por módulo
    revision/
      RevisionPage.jsx          → lista de actividades para revisar
      RevisionDetalle.jsx       → detalle con rendimientos + acción aprobar/devolver
    aprobacion/
      AprobacionPage.jsx        → lista para el admin de sucursal
      AprobacionDetalle.jsx     → detalle + aprobar/rechazar con motivo
    configuracion/
      ConfiguracionPage.jsx     → layout con sub-navegación
      sucursales/               → CRUD sucursales
      cecos/                    → CRUD CECOs
      cuarteles/                → CRUD cuarteles
      labores/                  → CRUD labores
      catastro/                 → especies y variedades
      calendario/               → feriados
    maestros/
      ColaboradoresPage.jsx
      ContratistasPage.jsx
      TrabajadoresPage.jsx
    rrhh/
      LicenciasPage.jsx
      VacacionesPage.jsx
      PermisosPage.jsx
      HorasExtrasPage.jsx
    reportes/
      DashboardPage.jsx
      RendimientosPage.jsx
      AsistenciaPage.jsx
    liquidaciones/
      LiquidacionesPage.jsx
    usuarios/
      UsuariosPage.jsx

  hooks/                 → hooks custom
    useAuth.js           → sesión, logout, datos del usuario
    useSucursal.js       → sucursal activa del JWT
    usePagination.js     → estado de paginación reutilizable

  store/                 → Zustand stores
    authStore.js         → token JWT, datos de usuario, sucursal activa

  lib/
    axios.js             → instancia Axios con interceptores
    queryClient.js       → configuración TanStack Query
    utils.js             → helpers: formatRUT, formatFecha, formatMoneda
```

---

## Autenticación y JWT

### Store de autenticación (`store/authStore.js`)

```js
import { create } from 'zustand'
import { persist } from 'zustand/middleware'

export const useAuthStore = create(persist(
  (set, get) => ({
    token: null,
    user: null,       // { sub, role, profile, sucursal }
    setAuth: (token, user) => set({ token, user }),
    logout: () => set({ token: null, user: null }),
    getSucursal: () => get().user?.sucursal,
    getRole: () => get().user?.role,
    getProfile: () => get().user?.profile,
  }),
  { name: 'lh-gestion-auth' }
))
```

### Instancia Axios (`lib/axios.js`)

```js
import axios from 'axios'
import { useAuthStore } from '../store/authStore'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,  // https://apilhtarja-...run.app
})

api.interceptors.request.use(config => {
  const token = useAuthStore.getState().token
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  res => res,
  err => {
    if (err.response?.status === 401) {
      useAuthStore.getState().logout()
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export default api
```

### Variables de entorno

```
VITE_API_URL=https://apilhtarja-927498545444.us-central1.run.app
```

Para desarrollo local:
```
VITE_API_URL=http://localhost:8000
```

---

## Funciones de API (`api/`)

Cada archivo exporta funciones que llaman a la API. No poner lógica de UI aquí.

### Ejemplo: `api/revision.js`

```js
import api from '../lib/axios'

export const getActividadesPendientes = (params) =>
  api.get('/api/gestion/revision/actividades', { params }).then(r => r.data)

export const getActividadDetalle = (id) =>
  api.get(`/api/gestion/revision/actividades/${id}`).then(r => r.data)

export const aprobarActividad = (id) =>
  api.post(`/api/gestion/revision/${id}/aprobar`).then(r => r.data)

export const devolverActividad = (id, observacion) =>
  api.post(`/api/gestion/revision/${id}/devolver`, { observacion }).then(r => r.data)
```

### Patrón de paginación en queries

La API retorna: `{ data: [], total, page, limit, pages }`

```js
// En el componente con TanStack Query:
const { data } = useQuery({
  queryKey: ['revision', 'actividades', { page, limit, ...filters }],
  queryFn: () => getActividadesPendientes({ page, limit, ...filters }),
})
// data.data → registros
// data.total → total para paginador
```

---

## Componentes clave

### DataTable.jsx

Tabla reutilizable para todos los listados. Props:

```jsx
<DataTable
  columns={columns}        // array de definición de columnas
  queryKey={['revision']}  // para invalidación de caché
  queryFn={getActividades} // función de api/
  filters={<FilterBar />}  // componente de filtros opcional
  onRowClick={handleClick} // navegar al detalle
/>
```

### StatusBadge.jsx

```jsx
// Mapeo de estados de actividad a colores Tailwind
const STATUS_MAP = {
  borrador:       { label: 'Borrador',        color: 'bg-gray-100 text-gray-700' },
  enviada:        { label: 'Enviada',          color: 'bg-blue-100 text-blue-700' },
  en_revision:    { label: 'En revisión',      color: 'bg-yellow-100 text-yellow-700' },
  aprobada_jefe:  { label: 'Rev. aprobada',    color: 'bg-teal-100 text-teal-700' },
  aprobada:       { label: 'Aprobada',         color: 'bg-green-100 text-green-700' },
  devuelta:       { label: 'Devuelta',         color: 'bg-orange-100 text-orange-700' },
  rechazada:      { label: 'Rechazada',        color: 'bg-red-100 text-red-700' },
}
```

---

## Navegación y rutas

### Estructura de rutas (`App.jsx` o `router.jsx`)

```jsx
<Routes>
  <Route path="/login" element={<LoginPage />} />

  <Route element={<ProtectedRoute />}>        {/* redirige a /login si no hay token */}
    <Route element={<AppLayout />}>

      <Route path="/" element={<Navigate to="/dashboard" />} />
      <Route path="/dashboard" element={<DashboardPage />} />

      {/* Flujo principal */}
      <Route path="/revision" element={<RevisionPage />} />
      <Route path="/revision/:id" element={<RevisionDetalle />} />
      <Route path="/aprobacion" element={<AprobacionPage />} />
      <Route path="/aprobacion/:id" element={<AprobacionDetalle />} />

      {/* Módulos secundarios */}
      <Route path="/maestros/colaboradores" element={<ColaboradoresPage />} />
      <Route path="/maestros/contratistas" element={<ContratistasPage />} />
      <Route path="/maestros/trabajadores" element={<TrabajadoresPage />} />

      <Route path="/rrhh/licencias" element={<LicenciasPage />} />
      <Route path="/rrhh/vacaciones" element={<VacacionesPage />} />
      <Route path="/rrhh/permisos" element={<PermisosPage />} />
      <Route path="/rrhh/horas-extras" element={<HorasExtrasPage />} />

      <Route path="/configuracion/*" element={<ConfiguracionPage />} />
      <Route path="/reportes/*" element={<ReportesPage />} />
      <Route path="/liquidaciones" element={<LiquidacionesPage />} />
      <Route path="/usuarios" element={<UsuariosPage />} />

    </Route>
  </Route>
</Routes>
```

### Control de acceso por rol en frontend

```jsx
// hooks/useAuth.js
export function useRequireRole(...roles) {
  const role = useAuthStore(s => s.getRole())
  const profile = useAuthStore(s => s.getProfile())
  return roles.includes(role) || roles.includes(profile)
}

// En el sidebar: ocultar items según perfil
// En páginas sensibles: redirigir si no tiene acceso
// Ojo: esto es solo UX — el backend siempre valida con require_role()
```

### Items del sidebar por perfil

| Perfil | Secciones visibles |
|--------|--------------------|
| `jefe_campo` | Dashboard, Revisión, Maestros, RRHH |
| `admin_sucursal` | Dashboard, Revisión, Aprobación, Maestros, RRHH, Configuración |
| `rrhh` | Dashboard, Maestros, RRHH, Reportes, Liquidaciones |
| `gerencia` | Dashboard, Reportes |
| `admin` | Todo |

---

## Flujo de revisión/aprobación (UI)

### RevisionPage.jsx — lo que muestra

- Tabla con actividades en estado `enviada` de la sucursal activa
- Columnas: fecha, labor, cuartel, capataz, cantidad rendimientos, estado
- Click en fila → navega a `/revision/:id`
- Filtros: fecha desde/hasta, labor, capataz

### RevisionDetalle.jsx — lo que muestra

- Header: datos de la actividad (fecha, labor, cuartel, ceco)
- Tabla de rendimientos: nombre trabajador/colaborador, rendimiento, unidad
- Dos botones: **Aprobar** (verde) y **Devolver** (naranja)
- Al devolver: modal con textarea para observación (obligatoria)
- Al aprobar: confirmación simple, luego redirige al listado

### AprobacionDetalle.jsx — igual pero

- Muestra la observación del jefe de campo si fue devuelta y corregida
- Botones: **Aprobar** (verde) y **Rechazar** (rojo)
- Al rechazar: modal con textarea para motivo (obligatorio)

---

## Convenciones de código React

- **Funciones, no clases** — solo functional components con hooks
- **`const` en vez de `function`** para componentes: `const MyPage = () => {}`
- **Named exports** para componentes, default export solo en páginas
- **TanStack Query para TODO el server state** — no `useState` para datos del servidor
- **React Hook Form + Zod** para todos los formularios con validación
- **No `useEffect` para fetching** — usar `useQuery`
- **Invalidar caché** después de mutations: `queryClient.invalidateQueries(['clave'])`
- **`async/await`** en las funciones de api/, nunca `.then()` encadenado en componentes

### Ejemplo de mutation con confirmación

```jsx
const mutation = useMutation({
  mutationFn: () => aprobarActividad(id),
  onSuccess: () => {
    queryClient.invalidateQueries(['revision', 'actividades'])
    toast.success('Actividad aprobada')
    navigate('/revision')
  },
  onError: (err) => toast.error(err.response?.data?.detail ?? 'Error al aprobar'),
})
```

---

## Formatos de datos (Chile)

```js
// lib/utils.js
export const formatFecha = (isoString) =>
  new Date(isoString).toLocaleDateString('es-CL')   // dd/MM/yyyy

export const formatMoneda = (n) =>
  new Intl.NumberFormat('es-CL', { style: 'currency', currency: 'CLP' }).format(n)

export const formatRUT = (rut, dv) => {
  const r = rut.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
  return `${r}-${dv}`
}
```

---

## Indicadores de estado en la UI

Estos mapeos deben ser consistentes en toda la app:

```js
// Colores de estado de actividad
export const ACTIVIDAD_ESTADOS = {
  borrador:      { label: 'Borrador',       badge: 'secondary' },
  enviada:       { label: 'Enviada',        badge: 'info'      },
  en_revision:   { label: 'En revisión',    badge: 'warning'   },
  aprobada_jefe: { label: 'Rev. aprobada',  badge: 'teal'      },
  aprobada:      { label: 'Aprobada',       badge: 'success'   },
  devuelta:      { label: 'Devuelta',       badge: 'orange'    },
  rechazada:     { label: 'Rechazada',      badge: 'danger'    },
}

// id_estado global (activo/inactivo en maestros)
export const ESTADO_ACTIVO = 1
export const ESTADO_INACTIVO = 2
```

---

## Variables de entorno requeridas

```
# .env.local (desarrollo)
VITE_API_URL=http://localhost:8000

# .env.production
VITE_API_URL=https://apilhtarja-927498545444.us-central1.run.app
```

---

## Orden de implementación recomendado

1. Setup del proyecto (Vite + React + Tailwind + shadcn)
2. `lib/axios.js` y `store/authStore.js`
3. `LoginPage.jsx` con llamada a `POST /api/auth/login`
4. `AppLayout.jsx` + `Sidebar.jsx` + `ProtectedRoute`
5. `components/shared/DataTable.jsx` — se reutiliza en todo
6. `pages/revision/` — prioridad de negocio #1
7. `pages/aprobacion/` — prioridad de negocio #2
8. El resto de módulos en paralelo
