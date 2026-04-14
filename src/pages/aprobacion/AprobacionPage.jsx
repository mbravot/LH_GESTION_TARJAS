import { useState, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { useAuthStore } from '@/store/authStore'
import { getActividadesBySucursal } from '@/api/aprobacion'
import { PageHeader } from '@/components/shared/PageHeader'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { Input } from '@/components/ui/input'
import { Button } from '@/components/ui/button'
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { Badge } from '@/components/ui/badge'
import { cn, formatFecha } from '@/lib/utils'
import { Search, Loader2, Filter, X } from 'lucide-react'

const ESTADO_MAP = {
  '1': 'enviada',
  '2': 'aprobada_jefe',
  '3': 'aprobada',
  '4': 'rechazada',
}

const TIPO_REND_MAP = {
  '1': 'Individual',
  '2': 'Grupal',
  '3': 'Multiple',
}

// Aprobacion shows only states 2 (REVISADA) and 3 (APROBADA)
const ESTADOS_APROBACION = ['2', '3']

const AprobacionPage = () => {
  const navigate = useNavigate()
  const user = useAuthStore((s) => s.user)
  const idSucursal = user?.sucursal?.id

  const [search, setSearch] = useState('')
  const [showFilters, setShowFilters] = useState(false)
  const [filtroContratista, setFiltroContratista] = useState('todos')
  const [filtroEstado, setFiltroEstado] = useState('todos')

  const { data: allActividades = [], isLoading, isError, error } = useQuery({
    queryKey: ['aprobacion', 'actividades', idSucursal],
    queryFn: () => getActividadesBySucursal(idSucursal),
    enabled: !!idSucursal,
  })

  // Filter only aprobacion-relevant states
  const actividades = useMemo(
    () => allActividades.filter((a) => ESTADOS_APROBACION.includes(String(a.id_estadoactividad))),
    [allActividades]
  )

  const contratistas = useMemo(() => {
    const set = new Set()
    actividades.forEach((a) => set.add(a.contratista || 'PROPIO'))
    return [...set].sort()
  }, [actividades])

  const filtered = useMemo(() => {
    let result = actividades

    if (search) {
      const s = search.toLowerCase()
      result = result.filter(
        (a) =>
          a.labor?.toLowerCase().includes(s) ||
          a.contratista?.toLowerCase().includes(s) ||
          a.nombre_usuario?.toLowerCase().includes(s) ||
          a.nombre_ceco?.toLowerCase().includes(s)
      )
    }

    if (filtroContratista !== 'todos') {
      result = result.filter((a) =>
        filtroContratista === 'PROPIO'
          ? !a.contratista || a.id_tipotrabajador === '1'
          : a.contratista === filtroContratista
      )
    }

    if (filtroEstado !== 'todos') {
      result = result.filter((a) => String(a.id_estadoactividad) === filtroEstado)
    }

    return result
  }, [actividades, search, filtroContratista, filtroEstado])

  const clearFilters = () => {
    setSearch('')
    setFiltroContratista('todos')
    setFiltroEstado('todos')
  }

  const hasActiveFilters =
    search || filtroContratista !== 'todos' || filtroEstado !== 'todos'

  return (
    <div className="space-y-6">
      <PageHeader
        title="Aprobacion de Tarjas"
        description={`${filtered.length} actividades pendientes de aprobacion`}
      />

      {/* Search + filter toggle */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-text-secondary" />
          <Input
            placeholder="Buscar por labor, contratista, usuario..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="pl-9"
          />
        </div>
        <Button
          variant={showFilters ? 'default' : 'outline'}
          onClick={() => setShowFilters(!showFilters)}
          className={showFilters ? 'bg-primary text-white' : ''}
        >
          <Filter className="h-4 w-4 mr-2" />
          Filtros
          {hasActiveFilters && (
            <Badge className="ml-2 bg-warning text-white text-xs px-1.5">!</Badge>
          )}
        </Button>
        {hasActiveFilters && (
          <Button variant="ghost" onClick={clearFilters} className="text-text-secondary">
            <X className="h-4 w-4 mr-1" />
            Limpiar
          </Button>
        )}
      </div>

      {/* Filter panel */}
      {showFilters && (
        <div className="flex flex-wrap gap-3 p-4 bg-card rounded-lg border border-border">
          <div className="space-y-1">
            <label className="text-xs font-medium text-text-secondary">Contratista</label>
            <Select value={filtroContratista} onValueChange={setFiltroContratista}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Todos" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="todos">Todos</SelectItem>
                {contratistas.map((c) => (
                  <SelectItem key={c} value={c}>{c}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="space-y-1">
            <label className="text-xs font-medium text-text-secondary">Estado</label>
            <Select value={filtroEstado} onValueChange={setFiltroEstado}>
              <SelectTrigger className="w-48">
                <SelectValue placeholder="Todos" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="todos">Todos</SelectItem>
                <SelectItem value="2">Revisada</SelectItem>
                <SelectItem value="3">Aprobada</SelectItem>
              </SelectContent>
            </Select>
          </div>
        </div>
      )}

      {/* Table */}
      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="bg-muted/50">
              <TableHead className="font-semibold">Fecha</TableHead>
              <TableHead className="font-semibold">Labor</TableHead>
              <TableHead className="font-semibold">Personal</TableHead>
              <TableHead className="font-semibold">Tipo Rend.</TableHead>
              <TableHead className="font-semibold">CECO</TableHead>
              <TableHead className="font-semibold">Tarifa</TableHead>
              <TableHead className="font-semibold">Horario</TableHead>
              <TableHead className="font-semibold">Rend.</TableHead>
              <TableHead className="font-semibold">Estado</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={9} className="h-32 text-center">
                  <div className="flex items-center justify-center gap-2 text-text-secondary">
                    <Loader2 className="h-5 w-5 animate-spin" />
                    <span>Cargando actividades...</span>
                  </div>
                </TableCell>
              </TableRow>
            ) : isError ? (
              <TableRow>
                <TableCell colSpan={9} className="h-32 text-center text-error">
                  {error?.response?.data?.detail ?? 'Error al cargar actividades'}
                </TableCell>
              </TableRow>
            ) : filtered.length === 0 ? (
              <TableRow>
                <TableCell colSpan={9} className="h-32 text-center text-text-secondary">
                  No se encontraron actividades pendientes de aprobacion
                </TableCell>
              </TableRow>
            ) : (
              filtered.map((act) => (
                <TableRow
                  key={act.id}
                  className="cursor-pointer hover:bg-muted/50 transition-colors"
                  onClick={() => navigate(`/aprobacion/${act.id}`, { state: { actividad: act } })}
                >
                  <TableCell className="text-sm">{formatFecha(act.fecha)}</TableCell>
                  <TableCell className="font-medium">{act.labor}</TableCell>
                  <TableCell className="text-sm">
                    {act.contratista || 'Propio'}
                  </TableCell>
                  <TableCell className="text-sm">
                    {TIPO_REND_MAP[act.id_tiporendimiento] ?? act.tipo_rend}
                  </TableCell>
                  <TableCell className="text-sm text-text-secondary">
                    {act.nombre_ceco}
                  </TableCell>
                  <TableCell className="text-sm">${act.tarifa}</TableCell>
                  <TableCell className="text-sm text-text-secondary">
                    {act.hora_inicio} - {act.hora_fin}
                  </TableCell>
                  <TableCell>
                    <Badge
                      className={cn(
                        'text-xs',
                        act.tiene_rendimiento
                          ? 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300'
                          : 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300'
                      )}
                    >
                      {act.tiene_rendimiento ? 'Si' : 'No'}
                    </Badge>
                  </TableCell>
                  <TableCell>
                    <StatusBadge
                      status={ESTADO_MAP[act.id_estadoactividad] ?? 'borrador'}
                    />
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>
    </div>
  )
}

export default AprobacionPage
