import { useEffect, useState } from 'react'
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts'
import api from '../services/api'
import StatCard from '../components/StatCard'

const months = ['Ian', 'Feb', 'Mar', 'Apr', 'Mai', 'Iun', 'Iul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

export default function Dashboard() {
  const [stats, setStats]     = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError]     = useState('')

  useEffect(() => {
    Promise.all([
      api.get('/properties'),
      api.get('/transactions'),
      api.get('/contracts'),
      api.get('/auctions'),
    ])
      .then(([props, trans, contr, auct]) => {
        const properties   = props.data
        const transactions = trans.data
        const contracts    = contr.data
        const auctions     = auct.data

        const totalValoare = properties.reduce((s, p) => s + parseFloat(p.valoareInventar || 0), 0)

        // Evolutie valoare pe luni (simulata din datele reale)
        const chartData = months.map((m, i) => {
          const factor = 0.7 + i * 0.025 + Math.sin(i) * 0.05
          return { luna: m, valoare: Math.round((totalValoare * factor) / 1000) / 1000 }
        })

        // Bunuri dupa tip
        const byTip = properties.reduce((acc, p) => {
          acc[p.tip] = (acc[p.tip] || 0) + 1
          return acc
        }, {})
        const tipChart = Object.entries(byTip).map(([tip, count]) => ({ tip, count }))

        setStats({
          nrProperties:  properties.length,
          nrActiv:       properties.filter((p) => p.status === 'activ').length,
          nrTransactions: transactions.length,
          nrInDerulare:  transactions.filter((t) => t.status === 'inDerulare').length,
          nrContracts:   contracts.length,
          nrContracteActive: contracts.filter((c) => c.status === 'activ').length,
          nrAuctions:    auctions.length,
          nrAuctActive:  auctions.filter((a) => ['activa','publicata'].includes(a.status)).length,
          totalValoare,
          chartData,
          tipChart,
          recentTransactions: transactions.slice(0, 5),
          recentAuctions:     auctions.slice(0, 5),
        })
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }, [])

  const formatRON = (v) =>
    v >= 1_000_000
      ? `${(v / 1_000_000).toFixed(2)} mil. RON`
      : `${v.toLocaleString('ro-RO')} RON`

  if (loading) return <div className="p-8 text-gray-400">Se încarcă...</div>
  if (error)   return <div className="p-8 text-red-600">Eroare: {error}</div>

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="bg-gradient-to-r from-primary-700 to-primary-800 rounded-xl p-6 text-white">
        <h1 className="text-2xl font-bold">Bun venit în e-Patrimoniu</h1>
        <p className="text-white/80 mt-1 text-sm">Evidența bunurilor imobiliare ale unității administrativ-teritoriale</p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 xl:grid-cols-4 gap-4">
        <StatCard label="Bunuri Imobile" value={stats.nrProperties} sub={`Active: ${stats.nrActiv}`} icon="⌂" color="green" />
        <StatCard label="Tranzacții" value={stats.nrTransactions} sub={`În derulare: ${stats.nrInDerulare}`} icon="⇄" color="blue" />
        <StatCard label="Contracte" value={stats.nrContracts} sub={`Active: ${stats.nrContracteActive}`} icon="📄" color="teal" />
        <StatCard label="Licitații" value={stats.nrAuctions} sub={`Active/Publicate: ${stats.nrAuctActive}`} icon="⚖" color="orange" />
      </div>

      {/* Valoare totala */}
      <div className="card bg-gradient-to-r from-emerald-50 to-teal-50 border-emerald-200">
        <p className="text-sm text-gray-500 mb-1">Valoare totală patrimoniu (inventar)</p>
        <p className="text-3xl font-bold text-primary-700">{formatRON(stats.totalValoare)}</p>
      </div>

      {/* Charts */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <div className="card">
          <h2 className="text-base font-semibold text-gray-800 mb-4">Evoluția valorii patrimoniului</h2>
          <p className="text-xs text-gray-400 mb-3">Valori în milioane RON</p>
          <ResponsiveContainer width="100%" height={220}>
            <LineChart data={stats.chartData}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="luna" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip formatter={(v) => [`${v.toFixed(3)} mil.`, 'Valoare']} />
              <Line type="monotone" dataKey="valoare" stroke="#2D6A4F" strokeWidth={2} dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </div>

        <div className="card">
          <h2 className="text-base font-semibold text-gray-800 mb-4">Bunuri imobile după tip</h2>
          <ResponsiveContainer width="100%" height={220}>
            <BarChart data={stats.tipChart} margin={{ top: 5, right: 10, left: -20, bottom: 5 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f1f5f9" />
              <XAxis dataKey="tip" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="count" fill="#2D6A4F" radius={[4, 4, 0, 0]} name="Număr" />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* Recent tables */}
      <div className="grid grid-cols-1 xl:grid-cols-2 gap-4">
        <div className="card">
          <h2 className="text-base font-semibold text-gray-800 mb-4">Tranzacții recente</h2>
          {stats.recentTransactions.length === 0 ? (
            <p className="text-gray-400 text-sm">Nicio tranzacție.</p>
          ) : (
            <div className="space-y-2">
              {stats.recentTransactions.map((t) => (
                <div key={t.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-gray-800 truncate">{t.propertyDenumire || '—'}</p>
                    <p className="text-xs text-gray-400 capitalize">{t.tip}</p>
                  </div>
                  <StatusBadge status={t.status} />
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="card">
          <h2 className="text-base font-semibold text-gray-800 mb-4">Licitații recente</h2>
          {stats.recentAuctions.length === 0 ? (
            <p className="text-gray-400 text-sm">Nicio licitație.</p>
          ) : (
            <div className="space-y-2">
              {stats.recentAuctions.map((a) => (
                <div key={a.id} className="flex items-center justify-between py-2 border-b border-gray-100 last:border-0">
                  <div className="min-w-0">
                    <p className="text-sm font-medium text-gray-800 truncate">{a.titlu}</p>
                    <p className="text-xs text-gray-400">{a.propertyDenumire || '—'}</p>
                  </div>
                  <StatusBadge status={a.status} />
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

function StatusBadge({ status }) {
  const cls = {
    activ: 'badge-activ', activa: 'badge-activa', publicata: 'badge-publicata',
    atribuita: 'badge-atribuita', draft: 'badge-draft', inactiv: 'badge-inactiv',
    finalizata: 'badge-finalizat', finalizat: 'badge-finalizat', expirat: 'badge-expirat',
    anulata: 'badge-anulat', anulat: 'badge-anulat', inLitigiu: 'badge-inLitigiu',
    inDerulare: 'badge-activ', aprobata: 'badge-publicata', initiata: 'badge-draft',
  }
  return <span className={cls[status] || 'badge-inactiv'}>{status}</span>
}
