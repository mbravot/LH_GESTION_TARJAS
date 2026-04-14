# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev       # Start dev server (Vite HMR)
npm run build     # Production build to dist/
npm run lint      # ESLint check
npm run preview   # Serve production build locally
```

Add shadcn components: `npx shadcn@latest add <component>`

## Architecture

**Frontend-only SPA** — React 19 + Vite consuming a FastAPI backend. The full architecture spec is in [GESTION_TARJA_FRONTEND.md](GESTION_TARJA_FRONTEND.md) — read it before creating new pages or components.

### Key layers

| Layer | Path | Purpose |
|-------|------|---------|
| API functions | `src/api/` | One file per module, pure HTTP calls, no UI logic |
| Zustand store | `src/store/authStore.js` | JWT token + user (persisted to localStorage as `lh-gestion-auth`) |
| Axios instance | `src/lib/axios.js` | Injects JWT header; redirects to `/login` on 401 |
| TanStack Query | `src/lib/queryClient.js` | All server state; never `useState` for API data |
| Pages | `src/pages/<module>/` | One folder per business module |
| Shared components | `src/components/shared/` | `DataTable`, `StatusBadge`, `ConfirmDialog`, `PageHeader` |
| shadcn/ui | `src/components/ui/` | Base components (Tailwind v4 CSS variables, `base-nova` style) |

### Path alias

`@/` resolves to `src/` (configured in `vite.config.js`).

### Auth flow

JWT is decoded from the login response and stored in Zustand. The `user` object shape is `{ sub, role, profile, sucursal }`. Role-based UI visibility is handled in `hooks/useAuth.js` via `useRequireRole()` — the backend always enforces permissions independently.

### API pagination contract

All list endpoints return `{ data: [], total, page, limit, pages }`. Use `data.data` for records and `data.total` for the paginator.

## Code conventions

- Functional components only, `const MyComponent = () => {}` with named exports; default export only for page-level components.
- TanStack Query (`useQuery` / `useMutation`) for all server state. No `useEffect` for fetching.
- React Hook Form + Zod for all forms with validation.
- After mutations, invalidate the relevant query key: `queryClient.invalidateQueries(['key'])`.
- Error toasts: `toast.error(err.response?.data?.detail ?? 'Error genérico')`.
- Dates formatted as `dd/MM/yyyy` (Chilean locale) using `formatFecha` from `lib/utils.js`.
- Currency formatted as CLP using `formatMoneda` from `lib/utils.js`.

## Environment variables

```
VITE_API_URL=http://localhost:8000          # .env.local
VITE_API_URL=https://apilhtarja-...run.app  # .env.production
```

## Activity status values

`borrador` → `enviada` → `en_revision` → `aprobada_jefe` → `aprobada`  
Deviation paths: `devuelta` (returned by jefe_campo), `rechazada` (rejected by admin_sucursal).

Use `ACTIVIDAD_ESTADOS` constants (defined in the spec) for labels and badge variants — never hardcode status strings in component logic.
