import { Navigate } from 'react-router-dom'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import { zodResolver } from '@hookform/resolvers/zod'
import { useAuthStore } from '@/store/authStore'
import { useLogin } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Label } from '@/components/ui/label'
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'

const loginSchema = z.object({
  usuario: z.string().min(1, 'Usuario es requerido'),
  clave: z.string().min(1, 'Clave es requerida'),
})

const LoginPage = () => {
  const token = useAuthStore((s) => s.token)
  const loginMutation = useLogin()

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm({
    resolver: zodResolver(loginSchema),
    defaultValues: { usuario: '', clave: '' },
  })

  if (token) {
    return <Navigate to="/dashboard" replace />
  }

  const onSubmit = (data) => {
    loginMutation.mutate(data)
  }

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center space-y-2">
          <CardTitle className="text-3xl font-bold text-primary">
            LH Gestion Tarjas
          </CardTitle>
          <CardDescription>
            Gestion de Tarjas - La Hornilla
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="usuario">Usuario</Label>
              <Input
                id="usuario"
                placeholder="Ingrese su usuario"
                autoComplete="username"
                {...register('usuario')}
              />
              {errors.usuario && (
                <p className="text-sm text-error">{errors.usuario.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <Label htmlFor="clave">Clave</Label>
              <Input
                id="clave"
                type="password"
                placeholder="Ingrese su clave"
                autoComplete="current-password"
                {...register('clave')}
              />
              {errors.clave && (
                <p className="text-sm text-error">{errors.clave.message}</p>
              )}
            </div>

            <Button
              type="submit"
              className="w-full bg-primary hover:bg-primary-dark text-white"
              disabled={loginMutation.isPending}
            >
              {loginMutation.isPending ? 'Ingresando...' : 'Ingresar'}
            </Button>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}

export default LoginPage
