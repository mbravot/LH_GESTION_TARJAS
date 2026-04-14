import { useState } from 'react'
import { useParams, useNavigate, useLocation } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { getRendimientos, aprobarActividad, rechazarActividad } from '@/api/aprobacion'
import { StatusBadge } from '@/components/shared/StatusBadge'
import { ConfirmDialog } from '@/components/shared/ConfirmDialog'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Textarea } from '@/components/ui/textarea'
import { Label } from '@/components/ui/label'
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '@/components/ui/dialog'
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table'
import { formatFecha } from '@/lib/utils'
import {
  ArrowLeft,
  Calendar,
  User,
  Briefcase,
  Building,
  BarChart3,
  Clock,
  DollarSign,
  MapPin,
  FolderOpen,
  Loader2,
  CheckCircle,
  XCircle,
} from 'lucide-react'

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

const InfoRow = ({ icon: Icon, label, value }) => (
  <div className="flex items-center gap-3 py-2">
    <Icon className="h-4 w-4 text-primary shrink-0" />
    <span className="text-sm text-text-secondary w-32 shrink-0">{label}</span>
    <span className="text-sm font-medium">{value ?? '-'}</span>
  </div>
)

const AprobacionDetalle = () => {
  const { id } = useParams()
  const navigate = useNavigate()
  const location = useLocation()
  const queryClient = useQueryClient()

  const actividad = location.state?.actividad

  const [showAprobar, setShowAprobar] = useState(false)
  const [showRechazar, setShowRechazar] = useState(false)
  const [motivo, setMotivo] = useState('')

  const {
    data: rendimientos = [],
    isLoading: loadingRend,
  } = useQuery({
    queryKey: ['aprobacion', 'rendimientos', id],
    queryFn: () =>
      getRendimientos(id, {
        idTipotrabajador: actividad?.id_tipotrabajador,
        idTiporendimiento: actividad?.id_tiporendimiento,
        idContratista: actividad?.id_contratista,
      }),
    enabled: !!id && !!actividad,
  })

  const aprobarMutation = useMutation({
    mutationFn: () => aprobarActividad(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['aprobacion'] })
      toast.success('Actividad aprobada correctamente')
      navigate('/aprobacion')
    },
    onError: (err) => {
      toast.error(err.response?.data?.detail ?? 'Error al aprobar')
    },
  })

  const rechazarMutation = useMutation({
    mutationFn: () => rechazarActividad(id, motivo),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['aprobacion'] })
      toast.success('Actividad rechazada correctamente')
      navigate('/aprobacion')
    },
    onError: (err) => {
      toast.error(err.response?.data?.detail ?? 'Error al rechazar')
    },
  })

  const handleRechazar = () => {
    if (!motivo.trim()) {
      toast.error('Debe ingresar el motivo del rechazo')
      return
    }
    rechazarMutation.mutate()
  }

  if (!actividad) {
    return (
      <div className="space-y-4">
        <Button variant="ghost" onClick={() => navigate('/aprobacion')}>
          <ArrowLeft className="h-4 w-4 mr-2" />
          Volver
        </Button>
        <p className="text-text-secondary text-center py-8">
          No se encontraron datos de la actividad. Vuelve al listado y selecciona una.
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="ghost" onClick={() => navigate('/aprobacion')}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Volver
          </Button>
          <div>
            <h1 className="text-xl font-bold text-foreground">
              Aprobacion de Actividad
            </h1>
            <p className="text-sm text-text-secondary">ID: {id}</p>
          </div>
        </div>
        <StatusBadge
          status={ESTADO_MAP[actividad.id_estadoactividad] ?? 'borrador'}
        />
      </div>

      {/* Activity info */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">Datos de la Actividad</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-x-8">
            <InfoRow icon={Calendar} label="Fecha" value={formatFecha(actividad.fecha)} />
            <InfoRow icon={User} label="Usuario" value={actividad.nombre_usuario} />
            <InfoRow icon={Briefcase} label="Labor" value={actividad.labor} />
            <InfoRow
              icon={Building}
              label="Personal"
              value={actividad.contratista || 'Propio'}
            />
            <InfoRow
              icon={BarChart3}
              label="Tipo Rendimiento"
              value={TIPO_REND_MAP[actividad.id_tiporendimiento] ?? actividad.tipo_rend}
            />
            <InfoRow icon={MapPin} label="Unidad" value={actividad.nombre_unidad} />
            <InfoRow
              icon={FolderOpen}
              label="CECO"
              value={`${actividad.nombre_tipoceco} - ${actividad.nombre_ceco}`}
            />
            <InfoRow icon={DollarSign} label="Tarifa" value={`$${actividad.tarifa}`} />
            <InfoRow
              icon={Clock}
              label="Horario"
              value={`${actividad.hora_inicio} - ${actividad.hora_fin}`}
            />
          </div>
        </CardContent>
      </Card>

      {/* Rendimientos table */}
      <Card>
        <CardHeader>
          <CardTitle className="text-lg">
            Rendimientos
            {!loadingRend && (
              <span className="ml-2 text-sm font-normal text-text-secondary">
                ({rendimientos.length} registros)
              </span>
            )}
          </CardTitle>
        </CardHeader>
        <CardContent>
          {loadingRend ? (
            <div className="flex items-center justify-center py-8 gap-2 text-text-secondary">
              <Loader2 className="h-5 w-5 animate-spin" />
              <span>Cargando rendimientos...</span>
            </div>
          ) : rendimientos.length === 0 ? (
            <p className="text-center py-8 text-text-secondary">
              No hay rendimientos registrados para esta actividad
            </p>
          ) : (
            <div className="rounded-lg border border-border overflow-hidden">
              <Table>
                <TableHeader>
                  <TableRow className="bg-muted/50">
                    <TableHead className="font-semibold">Colaborador</TableHead>
                    <TableHead className="font-semibold">Labor</TableHead>
                    <TableHead className="font-semibold text-right">Cantidad</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {rendimientos.map((rend, idx) => (
                    <TableRow key={rend.id ?? idx}>
                      <TableCell className="font-medium">
                        {rend.nombre_colaborador ?? rend.nombre ?? '-'}
                      </TableCell>
                      <TableCell className="text-sm">
                        {rend.labor ?? '-'}
                      </TableCell>
                      <TableCell className="text-right font-mono">
                        {rend.cantidad ?? '-'}
                      </TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Action buttons */}
      <div className="flex gap-3 justify-end">
        <Button
          variant="outline"
          className="border-error text-error hover:bg-error/10"
          onClick={() => setShowRechazar(true)}
        >
          <XCircle className="h-4 w-4 mr-2" />
          Rechazar
        </Button>
        <Button
          className="bg-success hover:bg-success/80 text-white"
          onClick={() => setShowAprobar(true)}
        >
          <CheckCircle className="h-4 w-4 mr-2" />
          Aprobar
        </Button>
      </div>

      {/* Approve confirmation */}
      <ConfirmDialog
        open={showAprobar}
        onOpenChange={setShowAprobar}
        title="Aprobar actividad"
        description="Esta seguro que desea aprobar esta actividad? Esta accion no se puede deshacer."
        confirmLabel="Aprobar"
        onConfirm={() => aprobarMutation.mutate()}
        isLoading={aprobarMutation.isPending}
      />

      {/* Reject dialog with reason */}
      <Dialog open={showRechazar} onOpenChange={setShowRechazar}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Rechazar actividad</DialogTitle>
            <DialogDescription>
              Ingrese el motivo del rechazo de esta actividad.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-2">
            <Label htmlFor="motivo">Motivo</Label>
            <Textarea
              id="motivo"
              placeholder="Ingrese el motivo del rechazo..."
              value={motivo}
              onChange={(e) => setMotivo(e.target.value)}
              rows={4}
            />
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowRechazar(false)}>
              Cancelar
            </Button>
            <Button
              className="bg-error hover:bg-error/80 text-white"
              onClick={handleRechazar}
              disabled={rechazarMutation.isPending}
            >
              {rechazarMutation.isPending ? 'Procesando...' : 'Rechazar'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}

export default AprobacionDetalle
