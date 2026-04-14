import { useAuthStore } from '@/store/authStore'
import { useLogout } from '@/hooks/useAuth'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

const DashboardPage = () => {
  const user = useAuthStore((s) => s.user)
  const logout = useLogout()

  return (
    <div className="min-h-screen bg-surface flex items-center justify-center p-4">
      <Card className="w-full max-w-lg">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl text-primary">
            Bienvenido, {user?.profile}
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-text-secondary">Usuario</p>
              <p className="font-medium">{user?.sub}</p>
            </div>
            <div>
              <p className="text-text-secondary">Rol</p>
              <p className="font-medium">{user?.role}</p>
            </div>
            <div>
              <p className="text-text-secondary">Sucursal</p>
              <p className="font-medium">{user?.sucursal?.nombre}</p>
            </div>
            <div>
              <p className="text-text-secondary">ID Sucursal</p>
              <p className="font-medium">{user?.sucursal?.id}</p>
            </div>
          </div>

          <div className="flex gap-2 justify-center pt-4">
            <Button
              variant="outline"
              onClick={() => document.documentElement.classList.toggle('dark')}
            >
              Toggle Dark Mode
            </Button>
            <Button
              className="bg-error hover:bg-error/80 text-white"
              onClick={logout}
            >
              Cerrar Sesion
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}

export default DashboardPage
