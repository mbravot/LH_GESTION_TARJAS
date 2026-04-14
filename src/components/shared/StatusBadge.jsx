import { Badge } from '@/components/ui/badge'
import { cn } from '@/lib/utils'

// Activity status colors
const ACTIVIDAD_STATUS = {
  borrador: { label: 'Borrador', className: 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-300' },
  enviada: { label: 'Enviada', className: 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300' },
  en_revision: { label: 'En revision', className: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300' },
  aprobada_jefe: { label: 'Rev. aprobada', className: 'bg-teal-100 text-teal-700 dark:bg-teal-900 dark:text-teal-300' },
  aprobada: { label: 'Aprobada', className: 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300' },
  devuelta: { label: 'Devuelta', className: 'bg-orange-100 text-orange-700 dark:bg-orange-900 dark:text-orange-300' },
  rechazada: { label: 'Rechazada', className: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300' },
}

// Generic active/inactive status
const ESTADO_STATUS = {
  1: { label: 'Activo', className: 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300' },
  2: { label: 'Inactivo', className: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300' },
}

export const StatusBadge = ({ status, type = 'actividad' }) => {
  const map = type === 'actividad' ? ACTIVIDAD_STATUS : ESTADO_STATUS
  const config = map[status]

  if (!config) {
    return (
      <Badge variant="outline" className="text-xs">
        {String(status)}
      </Badge>
    )
  }

  return (
    <Badge className={cn('text-xs font-medium border-0', config.className)}>
      {config.label}
    </Badge>
  )
}

export const ACTIVIDAD_ESTADOS = ACTIVIDAD_STATUS
export const ESTADO_ACTIVO = 1
export const ESTADO_INACTIVO = 2
