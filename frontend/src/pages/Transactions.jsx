import { useEffect, useState } from 'react'
import api from '../services/api'
import { useAuth } from '../contexts/AuthContext'
import Modal from '../components/Modal'

const TYPES = ['vanzare','cumparare','inchiriere','concesionare','dareAdministrare',
               'dareFolosintaGratuita','comodat','schimbImobiliar','transfer',
               'preluarePatrimoniu','scoatereEvidenta','modificareValoare']
const STATUSES = ['initiata','aprobata','inDerulare','finalizata','anulata']

const STATUS_CLS = {
  initiata: 'badge-draft', aprobata: 'badge-publicata', inDerulare: 'badge-activ',
  finalizata: 'badge-finalizat', anulata: 'badge-anulat',
}

export default function Transactions() {
  const { isStaff } = useAuth()
  const [data, setData]   = useState([])
  const [props, setProps] = useState([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState(null)
  const [selected, setSelected] = useState(null)
  const [form, setForm]   = useState({ propertyId: '', propertyDenumire: '', tip: TYPES[0], descriere: '', numarHcl: '', dataTransactie: '', note: '' })
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')

  const load = () => {
    setLoading(true)
    Promise.all([api.get('/transactions'), api.get('/properties')])
      .then(([t, p]) => { setData(t.data); setProps(p.data) })
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }))

  const handlePropertyChange = (id) => {
    const p = props.find((x) => x.id === id)
    setForm((f) => ({ ...f, propertyId: id, propertyDenumire: p?.denumire || '' }))
  }

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/transactions', form)
      setModal(null)
      load()
    } catch (e) { alert(e.message) } finally { setSaving(false) }
  }

  const updateStatus = async (id, status) => {
    try {
      await api.put(`/transactions/${id}/status`, { status })
      load()
    } catch (e) { alert(e.message) }
  }

  const filtered = data.filter((t) =>
    search === '' ||
    t.propertyDenumire?.toLowerCase().includes(search.toLowerCase()) ||
    t.tip?.toLowerCase().includes(search.toLowerCase()) ||
    t.numarHcl?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900">Tranzacții</h1>
          <p className="text-sm text-gray-500">{data.length} tranzacții</p>
        </div>
        {isStaff && (
          <button onClick={() => { setForm({ propertyId: '', propertyDenumire: '', tip: TYPES[0], descriere: '', numarHcl: '', dataTransactie: '', note: '' }); setModal('add') }} className="btn-primary">
            + Adaugă tranzacție
          </button>
        )}
      </div>

      <input className="input max-w-xs" placeholder="Caută bun, tip, HCL..." value={search} onChange={(e) => setSearch(e.target.value)} />

      {loading ? <p className="text-gray-400 text-sm">Se încarcă...</p> : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['Bun imobil', 'Tip', 'Nr. HCL', 'Data', 'Status', ''].map((h) => (
                  <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.length === 0 && <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">Nicio înregistrare.</td></tr>}
              {filtered.map((t) => (
                <tr key={t.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <p className="font-medium text-gray-800">{t.propertyDenumire || '—'}</p>
                    <p className="text-xs text-gray-400 line-clamp-1">{t.descriere}</p>
                  </td>
                  <td className="px-4 py-3 text-gray-600 capitalize text-xs">{t.tip}</td>
                  <td className="px-4 py-3 text-gray-600 text-xs">{t.numarHcl}</td>
                  <td className="px-4 py-3 text-gray-600 text-xs">{t.dataTransactie ? new Date(t.dataTransactie).toLocaleDateString('ro-RO') : '—'}</td>
                  <td className="px-4 py-3"><span className={STATUS_CLS[t.status] || 'badge-inactiv'}>{t.status}</span></td>
                  <td className="px-4 py-3">
                    {isStaff && t.status !== 'finalizata' && t.status !== 'anulata' && (
                      <select
                        className="text-xs border border-gray-200 rounded px-2 py-1"
                        value={t.status}
                        onChange={(e) => updateStatus(t.id, e.target.value)}
                      >
                        {STATUSES.map((s) => <option key={s}>{s}</option>)}
                      </select>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {modal === 'add' && (
        <Modal title="Adaugă tranzacție" onClose={() => setModal(null)} size="lg">
          <form onSubmit={handleSave} className="space-y-4">
            <div>
              <label className="label">Bun imobil *</label>
              <select className="input" value={form.propertyId} onChange={(e) => handlePropertyChange(e.target.value)} required>
                <option value="">Selectează...</option>
                {props.map((p) => <option key={p.id} value={p.id}>{p.denumire}</option>)}
              </select>
            </div>
            <div>
              <label className="label">Tip tranzacție *</label>
              <select className="input" value={form.tip} onChange={(e) => set('tip', e.target.value)}>
                {TYPES.map((t) => <option key={t}>{t}</option>)}
              </select>
            </div>
            <div>
              <label className="label">Nr. HCL *</label>
              <input className="input" value={form.numarHcl} onChange={(e) => set('numarHcl', e.target.value)} placeholder="HCL-2024-001" required />
            </div>
            <div>
              <label className="label">Data tranzacției *</label>
              <input className="input" type="date" value={form.dataTransactie} onChange={(e) => set('dataTransactie', e.target.value)} required />
            </div>
            <div>
              <label className="label">Descriere *</label>
              <textarea className="input" rows={3} value={form.descriere} onChange={(e) => set('descriere', e.target.value)} required />
            </div>
            <div>
              <label className="label">Note</label>
              <textarea className="input" rows={2} value={form.note} onChange={(e) => set('note', e.target.value)} />
            </div>
            <div className="flex gap-3 pt-2">
              <button type="submit" className="btn-primary" disabled={saving}>{saving ? 'Se salvează...' : 'Salvează'}</button>
              <button type="button" className="btn-secondary" onClick={() => setModal(null)}>Anulează</button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  )
}
