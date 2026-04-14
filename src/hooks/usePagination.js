import { useState, useCallback } from 'react'

const DEFAULT_LIMIT = 20

export const usePagination = (initialLimit = DEFAULT_LIMIT) => {
  const [page, setPage] = useState(1)
  const [limit, setLimit] = useState(initialLimit)

  const goToPage = useCallback((p) => setPage(p), [])
  const nextPage = useCallback(() => setPage((p) => p + 1), [])
  const prevPage = useCallback(() => setPage((p) => Math.max(1, p - 1)), [])
  const resetPage = useCallback(() => setPage(1), [])

  const changeLimit = useCallback((newLimit) => {
    setLimit(newLimit)
    setPage(1)
  }, [])

  return {
    page,
    limit,
    goToPage,
    nextPage,
    prevPage,
    resetPage,
    changeLimit,
  }
}
