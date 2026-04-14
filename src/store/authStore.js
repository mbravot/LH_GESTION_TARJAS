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
