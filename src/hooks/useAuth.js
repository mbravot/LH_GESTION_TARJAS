import { useMutation } from '@tanstack/react-query'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { useAuthStore } from '@/store/authStore'
import { login as loginApi } from '@/api/auth'

export const useLogin = () => {
  const navigate = useNavigate()

  return useMutation({
    mutationFn: ({ usuario, clave }) => loginApi(usuario, clave),
    onSuccess: (data) => {
      const user = {
        sub: data.usuario,
        role: data.id_rol,
        profile: data.nombre_usuario,
        sucursal: {
          id: data.id_sucursal,
          nombre: data.sucursal_nombre,
        },
      }
      useAuthStore.getState().setAuth(data.access_token, user)
      toast.success(`Bienvenido, ${data.nombre_usuario}`)
      navigate('/dashboard')
    },
    onError: (err) => {
      toast.error(err.response?.data?.error ?? 'Error al iniciar sesion')
    },
  })
}

export const useRequireRole = (...roles) => {
  const role = useAuthStore((s) => s.user?.role)
  const profile = useAuthStore((s) => s.user?.profile)
  return roles.includes(role) || roles.includes(profile)
}

export const useLogout = () => {
  const navigate = useNavigate()

  return () => {
    useAuthStore.getState().logout()
    navigate('/login')
  }
}
