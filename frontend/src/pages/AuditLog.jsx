import { useEffect, useState } from 'react'
import api from '../services/api'
import { useAuth } from '../contexts/AuthContext'

const ACTION_CLS = {
  CREATE: 'bg-green-100 text-green-700', create: 'bg-green-100 text-green-700',
  adaugare: 'bg-green-100 text-green-700',
  UPDATE: 'bg-blue-100 text-blue-700', update: 'bg-blue-100 text-blue-700',
  modificare: 'bg-blue-100 text-blue-700', actualizareStatus: 'bg-blue-100 text-blue-700',
  DELETE: 'bg-red-100 text-red-700', delete: 'bg-red-100 text-red-700',
  stergere: 'bg-red-100 text-red-700',
  VIEW: 'bg-gray-100 text-gray-600', view: 'bg-gray-100 text-gray-600',
}

export default function AuditLog() {
  const { isAdmin } = useAuth()
  const [data, setData]   = useState([])
  const [loading, setLoading] = useState(true)
  const [search, setSearch] = useState('')

  useEffect(() => {
    if (!isAdmin) return
    api.get('/audit')
      .then((r) => setData(r.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [isAdmin])

  const filtered = data.filter((e) =>
    search === '' ||
    e.userName?.toLowerCase().includes(search.toLowerCase()) ||
    e.actiune?.toLowerCase().includes(search.toLowerCase()) ||
    e.entitate?.toLowerCase().includes(search.toLowerCase()) ||
    e.detalii?.toLowerCase().includes(search.toLowerCase())
  )

  const fmtDate = (d) => {
    if (!d) return '—'
    return new Date(d).toLocaleString('ro-RO', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })
  }

  if (!isAdmin) return <div className="p-8 text-gray-400">Acces restricționat — doar administratori.</div>

  return (
    <div className="p-6 space-y-5">
      <div>
        <h1 className="text-xl font-bold text-gray-900">Jurnal de Audit</h1>
        <p className="text-sm text-gray-500">{data.length} intrări</p>
      </div>

      <input className="input max-w-xs" placeholder="Caută utilizator, acțiune, entitate..." value={search} onChange={(e) => setSearch(e.target.value)} />

      {loading ? <p className="text-gray-400 text-sm">Se încarcă...</p> : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['Timestamp', 'Utilizator', 'Acțiune', 'Entitate', 'Detalii', 'IP'].map((h) => (
                  <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.length === 0 && <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">Nicio înregistrare.</td></tr>}
              {filtered.map((e) => (
                <tr key={e.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 text-xs text-gray-500 whitespace-nowrap">{fmtDate(e.timestamp)}</td>
                  <td className="px-4 py-3 text-xs font-medium text-gray-700">{e.userName || e.userId}</td>
                  <td className="px-4 py-3">
                    <span className={`inline-flex px-2 py-0.5 rounded text-xs font-medium ${ACTION_CLS[e.actiune] || 'bg-gray-100 text-gray-600'}`}>
                      {e.actiune}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-xs text-gray-600">{e.entitate}</td>
                  <td className="px-4 py-3 text-xs text-gray-500 max-w-xs truncate">{e.detalii || '—'}</td>
                  <td className="px-4 py-3 text-xs text-gray-400 font-mono">{e.ipAddress || '—'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}
