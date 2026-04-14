import { clsx } from "clsx";
import { twMerge } from "tailwind-merge"

export function cn(...inputs) {
  return twMerge(clsx(inputs));
}

export const formatFecha = (isoString) =>
  new Date(isoString).toLocaleDateString('es-CL')

export const formatMoneda = (n) =>
  new Intl.NumberFormat('es-CL', {
    style: 'currency',
    currency: 'CLP',
  }).format(n)

export const formatRUT = (rut, dv) => {
  const r = rut.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')
  return `${r}-${dv}`
}
