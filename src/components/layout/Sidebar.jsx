import { NavLink, useLocation } from 'react-router-dom'
import { useAuthStore } from '@/store/authStore'
import { ScrollArea } from '@/components/ui/scroll-area'
import { Separator } from '@/components/ui/separator'
import {
  Tooltip,
  TooltipContent,
  TooltipTrigger,
} from '@/components/ui/tooltip'
import { cn } from '@/lib/utils'
import {
  LayoutDashboard,
  Search,
  CheckCircle,
  Users,
  Building2,
  Briefcase,
  Stethoscope,
  Palmtree,
  FileCheck,
  Clock,
  BarChart3,
  Settings,
  Receipt,
  UserCog,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react'

// Sidebar navigation structure
// Each section has a label, items, and allowed roles/profiles
const NAV_SECTIONS = [
  {
    label: 'Principal',
    items: [
      { label: 'Dashboard', path: '/dashboard', icon: LayoutDashboard },
    ],
    roles: ['admin', 'jefe_campo', 'admin_sucursal', 'rrhh', 'gerencia'],
  },
  {
    label: 'Gestion de Tarjas',
    items: [
      { label: 'Revision', path: '/revision', icon: Search },
      { label: 'Aprobacion', path: '/aprobacion', icon: CheckCircle },
    ],
    roles: ['admin', 'jefe_campo', 'admin_sucursal'],
  },
  {
    label: 'Maestros',
    items: [
      { label: 'Colaboradores', path: '/maestros/colaboradores', icon: Users },
      { label: 'Contratistas', path: '/maestros/contratistas', icon: Building2 },
      { label: 'Trabajadores', path: '/maestros/trabajadores', icon: Briefcase },
    ],
    roles: ['admin', 'jefe_campo', 'admin_sucursal', 'rrhh'],
  },
  {
    label: 'RRHH',
    items: [
      { label: 'Licencias', path: '/rrhh/licencias', icon: Stethoscope },
      { label: 'Vacaciones', path: '/rrhh/vacaciones', icon: Palmtree },
      { label: 'Permisos', path: '/rrhh/permisos', icon: FileCheck },
      { label: 'Horas Extras', path: '/rrhh/horas-extras', icon: Clock },
    ],
    roles: ['admin', 'jefe_campo', 'admin_sucursal', 'rrhh'],
  },
  {
    label: 'Reportes',
    items: [
      { label: 'Reportes', path: '/reportes', icon: BarChart3 },
    ],
    roles: ['admin', 'rrhh', 'gerencia'],
  },
  {
    label: 'Administracion',
    items: [
      { label: 'Configuracion', path: '/configuracion', icon: Settings },
      { label: 'Liquidaciones', path: '/liquidaciones', icon: Receipt },
      { label: 'Usuarios', path: '/usuarios', icon: UserCog },
    ],
    roles: ['admin', 'admin_sucursal'],
  },
]

const SidebarItem = ({ item, collapsed }) => {
  const location = useLocation()
  const isActive = location.pathname.startsWith(item.path)
  const Icon = item.icon

  const link = (
    <NavLink
      to={item.path}
      className={cn(
        'flex items-center gap-3 rounded-lg px-3 py-2 text-sm transition-colors',
        'hover:bg-sidebar-accent hover:text-sidebar-foreground',
        isActive
          ? 'bg-sidebar-accent text-sidebar-foreground font-medium'
          : 'text-sidebar-foreground/70'
      )}
    >
      <Icon className="h-5 w-5 shrink-0" />
      {!collapsed && <span>{item.label}</span>}
    </NavLink>
  )

  if (collapsed) {
    return (
      <Tooltip>
        <TooltipTrigger asChild>{link}</TooltipTrigger>
        <TooltipContent side="right">{item.label}</TooltipContent>
      </Tooltip>
    )
  }

  return link
}

export const Sidebar = ({ collapsed, onToggle }) => {
  const user = useAuthStore((s) => s.user)
  const userRole = user?.role

  // Filter sections by role. 'admin' sees everything.
  const visibleSections = NAV_SECTIONS.filter(
    (section) => userRole === 'admin' || section.roles.includes(userRole)
  )

  // For aprobacion: only admin_sucursal and admin can see it
  const filterItems = (section) => {
    return section.items.filter((item) => {
      if (item.path === '/aprobacion') {
        return userRole === 'admin' || userRole === 'admin_sucursal'
      }
      return true
    })
  }

  return (
    <aside
      className={cn(
        'flex flex-col h-screen bg-sidebar text-sidebar-foreground transition-all duration-300',
        collapsed ? 'w-16' : 'w-64'
      )}
    >
      {/* Logo / Brand */}
      <div className="flex items-center gap-3 px-4 h-16 shrink-0">
        <div className="h-8 w-8 rounded-lg bg-sidebar-foreground/20 flex items-center justify-center shrink-0">
          <span className="text-sm font-bold">LH</span>
        </div>
        {!collapsed && (
          <span className="font-semibold text-lg truncate">LH Gestion</span>
        )}
      </div>

      <Separator className="bg-sidebar-foreground/20" />

      {/* Navigation */}
      <ScrollArea className="flex-1 px-2 py-2">
        <nav className="space-y-4">
          {visibleSections.map((section) => {
            const items = filterItems(section)
            if (items.length === 0) return null

            return (
              <div key={section.label}>
                {!collapsed && (
                  <p className="px-3 mb-1 text-xs font-medium uppercase tracking-wider text-sidebar-foreground/50">
                    {section.label}
                  </p>
                )}
                <div className="space-y-1">
                  {items.map((item) => (
                    <SidebarItem
                      key={item.path}
                      item={item}
                      collapsed={collapsed}
                    />
                  ))}
                </div>
              </div>
            )
          })}
        </nav>
      </ScrollArea>

      <Separator className="bg-sidebar-foreground/20" />

      {/* Collapse toggle */}
      <button
        onClick={onToggle}
        className="flex items-center justify-center h-12 hover:bg-sidebar-accent transition-colors"
      >
        {collapsed ? (
          <ChevronRight className="h-5 w-5" />
        ) : (
          <ChevronLeft className="h-5 w-5" />
        )}
      </button>
    </aside>
  )
}
