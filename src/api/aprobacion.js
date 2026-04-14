import api from '@/lib/axios'

/**
 * Get all activities for a branch (same endpoint as revision).
 * Aprobacion filters for states 2 (REVISADA) and 3 (APROBADA) client-side.
 */
export const getActividadesBySucursal = async (idSucursal) => {
  const { data } = await api.get(`/api/actividades/sucursal/${idSucursal}`)
  return data
}

/**
 * Get rendimientos for an activity (same as revision).
 */
export const getRendimientos = async (actividadId, { idTipotrabajador, idTiporendimiento, idContratista } = {}) => {
  if (idTipotrabajador === '1' || idTipotrabajador === 1) {
    const { data } = await api.get(`/api/rendimientopropio/actividad/${actividadId}`)
    return data
  }

  if ((idTipotrabajador === '2' || idTipotrabajador === 2) &&
      (idTiporendimiento === '1' || idTiporendimiento === 1)) {
    const { data } = await api.get('/api/rendimientos/individual/contratista', {
      params: { id_actividad: actividadId },
    })
    return data
  }

  const { data } = await api.get(`/api/rendimientos/${actividadId}`)
  return data
}

/**
 * Approve activity (state 2 → 3).
 */
export const aprobarActividad = async (id) => {
  const { data } = await api.put(`/api/tarjas/${id}/aprobar`)
  return data
}

/**
 * Reject activity with reason (admin rejects back).
 */
export const rechazarActividad = async (id, motivo) => {
  const { data } = await api.put(`/api/tarjas/${id}/rechazar`, { motivo })
  return data
}
