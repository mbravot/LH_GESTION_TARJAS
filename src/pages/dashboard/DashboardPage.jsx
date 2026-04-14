import { useAuthStore } from '@/store/authStore'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'

const DashboardPage = () => {
  const user = useAuthStore((s) => s.user)

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold text-foreground">Dashboard</h1>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              Usuario
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-lg font-semibold">{user?.profile}</p>
            <p className="text-xs text-text-secondary">{user?.sub}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              Sucursal
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-lg font-semibold">{user?.sucursal?.nombre}</p>
            <p className="text-xs text-text-secondary">
              ID: {user?.sucursal?.id}
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              Rol
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-lg font-semibold">{user?.role}</p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-text-secondary">
              Estado
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-lg font-semibold text-success">Activo</p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Bienvenido a LH Gestion Tarjas</CardTitle>
        </CardHeader>
        <CardContent>
          <p className="text-text-secondary">
            Selecciona una opcion del menu lateral para comenzar.
          </p>
        </CardContent>
      </Card>
    </div>
  )
}

export default DashboardPage
