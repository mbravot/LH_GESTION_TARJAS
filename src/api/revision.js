import api from '@/lib/axios'

/**
 * Get all activities for a branch (sucursal).
 * Returns array of tarja objects.
 */
export const getActividadesBySucursal = async (idSucursal) => {
  const { data } = await api.get(`/api/actividades/sucursal/${idSucursal}`)
  return data
}

/**
 * Get rendimientos for an activity.
 * Endpoint varies by worker type and performance type.
 */
export const getRendimientos = async (actividadId, { idTipotrabajador, idTiporendimiento, idContratista } = {}) => {
  // Personal propio
  if (idTipotrabajador === '1' || idTipotrabajador === 1) {
    const { data } = await api.get(`/api/rendimientopropio/actividad/${actividadId}`)
    return data
  }

  // Contratista individual
  if ((idTipotrabajador === '2' || idTipotrabajador === 2) &&
      (idTiporendimiento === '1' || idTiporendimiento === 1)) {
    const { data } = await api.get('/api/rendimientos/individual/contratista', {
      params: { id_actividad: actividadId },
    })
    return data
  }

  // Grupal / Multiple
  const { data } = await api.get(`/api/rendimientos/${actividadId}`)
  return data
}

/**
 * Approve a tarja/activity.
 */
export const aprobarTarja = async (id) => {
  const { data } = await api.put(`/api/tarjas/${id}/aprobar`)
  return data
}

/**
 * Reject/return a tarja with an observation.
 */
export const rechazarTarja = async (id, motivo) => {
  const { data } = await api.put(`/api/tarjas/${id}/rechazar`, { motivo })
  return data
}
