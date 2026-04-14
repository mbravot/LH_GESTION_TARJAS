import api from '@/lib/axios'

export const login = async (usuario, clave) => {
  const { data } = await api.post('/api/auth/login', { usuario, clave })
  return data
}
