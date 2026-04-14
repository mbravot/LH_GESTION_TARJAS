import { useQuery } from '@tanstack/react-query'
import { usePagination } from '@/hooks/usePagination'
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
import { cn } from '@/lib/utils'
import {
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  Search,
  Loader2,
} from 'lucide-react'
import { useState, useCallback } from 'react'

/**
 * Reusable DataTable with server-side pagination.
 *
 * @param {Object} props
 * @param {Array} props.columns - Column definitions: { key, label, render?, className? }
 * @param {Array} props.queryKey - TanStack Query key base (e.g. ['revision', 'actividades'])
 * @param {Function} props.queryFn - API function receiving { page, limit, search, ...filters }
 * @param {ReactNode} [props.filters] - Optional filter component rendered above the table
 * @param {Object} [props.filterValues] - Current filter values merged into queryFn params
 * @param {Function} [props.onRowClick] - Called with row data on click
 * @param {boolean} [props.searchable=true] - Show search input
 * @param {string} [props.searchPlaceholder] - Search input placeholder text
 * @param {number} [props.defaultLimit=20] - Default rows per page
 */
export const DataTable = ({
  columns,
  queryKey,
  queryFn,
  filters,
  filterValues = {},
  onRowClick,
  searchable = true,
  searchPlaceholder = 'Buscar...',
  defaultLimit = 20,
}) => {
  const { page, limit, goToPage, nextPage, prevPage, resetPage, changeLimit } =
    usePagination(defaultLimit)
  const [search, setSearch] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')

  // Debounce search input
  const handleSearch = useCallback(
    (value) => {
      setSearch(value)
      clearTimeout(handleSearch._timeout)
      handleSearch._timeout = setTimeout(() => {
        setDebouncedSearch(value)
        resetPage()
      }, 400)
    },
    [resetPage]
  )

  const queryParams = {
    page,
    limit,
    ...(debouncedSearch && { search: debouncedSearch }),
    ...filterValues,
  }

  const { data, isLoading, isError, error } = useQuery({
    queryKey: [...queryKey, queryParams],
    queryFn: () => queryFn(queryParams),
  })

  // API returns: { data: [], total, page, limit, pages }
  const rows = data?.data ?? []
  const total = data?.total ?? 0
  const totalPages = data?.pages ?? 1

  return (
    <div className="space-y-4">
      {/* Search + Filters */}
      {(searchable || filters) && (
        <div className="flex flex-col sm:flex-row gap-3">
          {searchable && (
            <div className="relative flex-1 max-w-sm">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-text-secondary" />
              <Input
                placeholder={searchPlaceholder}
                value={search}
                onChange={(e) => handleSearch(e.target.value)}
                className="pl-9"
              />
            </div>
          )}
          {filters}
        </div>
      )}

      {/* Table */}
      <div className="rounded-lg border border-border bg-card overflow-hidden">
        <Table>
          <TableHeader>
            <TableRow className="bg-muted/50">
              {columns.map((col) => (
                <TableHead key={col.key} className={cn('font-semibold', col.className)}>
                  {col.label}
                </TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {isLoading ? (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-32 text-center">
                  <div className="flex items-center justify-center gap-2 text-text-secondary">
                    <Loader2 className="h-5 w-5 animate-spin" />
                    <span>Cargando...</span>
                  </div>
                </TableCell>
              </TableRow>
            ) : isError ? (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-32 text-center text-error">
                  {error?.response?.data?.detail ?? 'Error al cargar datos'}
                </TableCell>
              </TableRow>
            ) : rows.length === 0 ? (
              <TableRow>
                <TableCell colSpan={columns.length} className="h-32 text-center text-text-secondary">
                  No se encontraron registros
                </TableCell>
              </TableRow>
            ) : (
              rows.map((row, idx) => (
                <TableRow
                  key={row.id ?? idx}
                  className={cn(
                    onRowClick && 'cursor-pointer hover:bg-muted/50 transition-colors'
                  )}
                  onClick={() => onRowClick?.(row)}
                >
                  {columns.map((col) => (
                    <TableCell key={col.key} className={col.className}>
                      {col.render ? col.render(row) : row[col.key]}
                    </TableCell>
                  ))}
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </div>

      {/* Pagination */}
      {total > 0 && (
        <div className="flex items-center justify-between text-sm">
          <div className="flex items-center gap-2 text-text-secondary">
            <span>
              {(page - 1) * limit + 1}-{Math.min(page * limit, total)} de {total}
            </span>
            <Select
              value={String(limit)}
              onValueChange={(v) => changeLimit(Number(v))}
            >
              <SelectTrigger className="w-20 h-8">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="10">10</SelectItem>
                <SelectItem value="20">20</SelectItem>
                <SelectItem value="50">50</SelectItem>
                <SelectItem value="100">100</SelectItem>
              </SelectContent>
            </Select>
            <span>por pagina</span>
          </div>

          <div className="flex items-center gap-1">
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => goToPage(1)}
              disabled={page <= 1}
            >
              <ChevronsLeft className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={prevPage}
              disabled={page <= 1}
            >
              <ChevronLeft className="h-4 w-4" />
            </Button>
            <span className="px-3 text-text-secondary">
              {page} / {totalPages}
            </span>
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={nextPage}
              disabled={page >= totalPages}
            >
              <ChevronRight className="h-4 w-4" />
            </Button>
            <Button
              variant="outline"
              size="icon"
              className="h-8 w-8"
              onClick={() => goToPage(totalPages)}
              disabled={page >= totalPages}
            >
              <ChevronsRight className="h-4 w-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  )
}
