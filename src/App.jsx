import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { ProtectedRoute } from '@/components/shared/ProtectedRoute'
import { AppLayout } from '@/components/layout/AppLayout'
import LoginPage from '@/pages/auth/LoginPage'
import DashboardPage from '@/pages/dashboard/DashboardPage'

const App = () => {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<LoginPage />} />

        <Route element={<ProtectedRoute />}>
          <Route element={<AppLayout />}>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<DashboardPage />} />

            {/* Flujo principal - placeholder routes */}
            <Route path="/revision" element={<PlaceholderPage title="Revision de Tarjas" />} />
            <Route path="/aprobacion" element={<PlaceholderPage title="Aprobacion de Tarjas" />} />

            {/* Maestros */}
            <Route path="/maestros/colaboradores" element={<PlaceholderPage title="Colaboradores" />} />
            <Route path="/maestros/contratistas" element={<PlaceholderPage title="Contratistas" />} />
            <Route path="/maestros/trabajadores" element={<PlaceholderPage title="Trabajadores" />} />

            {/* RRHH */}
            <Route path="/rrhh/licencias" element={<PlaceholderPage title="Licencias" />} />
            <Route path="/rrhh/vacaciones" element={<PlaceholderPage title="Vacaciones" />} />
            <Route path="/rrhh/permisos" element={<PlaceholderPage title="Permisos" />} />
            <Route path="/rrhh/horas-extras" element={<PlaceholderPage title="Horas Extras" />} />

            {/* Reportes, Configuracion, etc */}
            <Route path="/reportes/*" element={<PlaceholderPage title="Reportes" />} />
            <Route path="/configuracion/*" element={<PlaceholderPage title="Configuracion" />} />
            <Route path="/liquidaciones" element={<PlaceholderPage title="Liquidaciones" />} />
            <Route path="/usuarios" element={<PlaceholderPage title="Usuarios" />} />
          </Route>
        </Route>

        <Route path="*" element={<Navigate to="/login" replace />} />
      </Routes>
    </BrowserRouter>
  )
}

// Temporary placeholder for routes not yet implemented
const PlaceholderPage = ({ title }) => (
  <div className="flex items-center justify-center h-64">
    <div className="text-center">
      <h2 className="text-2xl font-semibold text-foreground">{title}</h2>
      <p className="text-text-secondary mt-2">Pagina en construccion</p>
    </div>
  </div>
)

export default App
