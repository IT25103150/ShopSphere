import { useMemo, useState, type ReactNode } from 'react'

export interface Column<T> {
  header: string
  cell: (row: T) => ReactNode
  /** Provide a sort value to make the column sortable (client-side, current page). */
  sortValue?: (row: T) => string | number
  className?: string
}

interface TableProps<T> {
  columns: Column<T>[]
  rows: T[]
  rowKey: (row: T) => string | number
  rowClass?: (row: T) => string
  empty?: string
}

export function Table<T>({ columns, rows, rowKey, rowClass, empty = 'Nothing to show yet.' }: TableProps<T>) {
  const [sort, setSort] = useState<{ col: number; dir: 1 | -1 } | null>(null)
  const sorted = useMemo(() => {
    if (!sort) return rows
    const get = columns[sort.col].sortValue
    if (!get) return rows
    return [...rows].sort((a, b) => (get(a) > get(b) ? 1 : get(a) < get(b) ? -1 : 0) * sort.dir)
  }, [rows, sort, columns])

  return (
    <div className="table-wrap">
      <table className="table">
        <thead>
          <tr>
            {columns.map((c, i) => (
              <th
                key={c.header}
                className={c.sortValue ? 'sortable' : ''}
                onClick={c.sortValue ? () => setSort((s) => (s?.col === i ? { col: i, dir: (s.dir * -1) as 1 | -1 } : { col: i, dir: 1 })) : undefined}
                aria-sort={sort?.col === i ? (sort.dir === 1 ? 'ascending' : 'descending') : undefined}
              >
                {c.header}{sort?.col === i ? (sort.dir === 1 ? ' ▲' : ' ▼') : ''}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {sorted.length === 0 && (
            <tr><td colSpan={columns.length} style={{ textAlign: 'center', color: 'var(--muted)', padding: 32 }}>{empty}</td></tr>
          )}
          {sorted.map((r) => (
            <tr key={rowKey(r)} className={rowClass?.(r)}>
              {columns.map((c) => <td key={c.header} className={c.className}>{c.cell(r)}</td>)}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}

interface PaginationProps { page: number; totalPages: number; onChange: (p: number) => void }

export function Pagination({ page, totalPages, onChange }: PaginationProps) {
  if (totalPages <= 1) return null
  const pages: number[] = []
  for (let i = Math.max(0, page - 2); i <= Math.min(totalPages - 1, page + 2); i++) pages.push(i)
  return (
    <nav className="pagination" aria-label="Pagination">
      <button disabled={page === 0} onClick={() => onChange(page - 1)}>‹</button>
      {pages[0] > 0 && <><button onClick={() => onChange(0)}>1</button><span>…</span></>}
      {pages.map((p) => <button key={p} className={p === page ? 'active' : ''} onClick={() => onChange(p)} aria-current={p === page ? 'page' : undefined}>{p + 1}</button>)}
      {pages[pages.length - 1] < totalPages - 1 && <><span>…</span><button onClick={() => onChange(totalPages - 1)}>{totalPages}</button></>}
      <button disabled={page >= totalPages - 1} onClick={() => onChange(page + 1)}>›</button>
    </nav>
  )
}
