import { useEffect, useState } from 'react'
import api from '../services/api'
import { useAuth } from '../contexts/AuthContext'
import Modal from '../components/Modal'

const STATUSES = ['activ','prelungit','reziliat','expirat','finalizat','anulat']
const STATUS_CLS = {
  activ: 'badge-activ', prelungit: 'badge-publicata', reziliat: 'badge-anulat',
  expirat: 'badge-expirat', finalizat: 'badge-finalizat', anulat: 'badge-anulat',
}

const emptyForm = {
  propertyId: '', propertyDenumire: '', numarContract: '', parteContractanta: '',
  dataInceput: '', dataFinal: '', valoare: '', valutaMoneda: 'RON', status: 'activ', note: '',
}

export default function Contracts() {
  const { isStaff } = useAuth()
  const [data, setData]   = useState([])
  const [props, setProps] = useState([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState(null)
  const [selected, setSelected] = useState(null)
  const [form, setForm]   = useState(emptyForm)
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')

  const load = () => {
    setLoading(true)
    Promise.all([api.get('/contracts'), api.get('/properties')])
      .then(([c, p]) => { setData(c.data); setProps(p.data) })
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }))

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      const payload = { ...form, valoare: parseFloat(form.valoare) }
      if (modal === 'add') {
        await api.post('/contracts', payload)
      } else {
        await api.put(`/contracts/${selected.id}`, payload)
      }
      setModal(null)
      load()
    } catch (e) { alert(e.message) } finally { setSaving(false) }
  }

  const openEdit = (c) => {
    setSelected(c)
    setForm({
      propertyId: c.propertyId, propertyDenumire: c.propertyDenumire,
      numarContract: c.numarContract, parteContractanta: c.parteContractanta,
      dataInceput: c.dataInceput?.substring(0, 10),
      dataFinal: c.dataFinal?.substring(0, 10),
      valoare: c.valoare, valutaMoneda: c.valutaMoneda,
      status: c.status, note: c.note || '',
    })
    setModal('edit')
  }

  const filtered = data.filter((c) =>
    search === '' ||
    c.propertyDenumire?.toLowerCase().includes(search.toLowerCase()) ||
    c.numarContract?.toLowerCase().includes(search.toLowerCase()) ||
    c.parteContractanta?.toLowerCase().includes(search.toLowerCase())
  )

  const fmt = (v) => parseFloat(v || 0).toLocaleString('ro-RO', { minimumFractionDigits: 2 })

  const openAdd = () => { setForm(emptyForm); setModal('add') }

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900">Contracte</h1>
          <p className="text-sm text-gray-500">{data.length} contracte</p>
        </div>
        {isStaff && <button onClick={openAdd} className="btn-primary">+ Adaugă contract</button>}
      </div>

      <input className="input max-w-xs" placeholder="Caută bun, nr. contract, parte..." value={search} onChange={(e) => setSearch(e.target.value)} />

      {loading ? <p className="text-gray-400 text-sm">Se încarcă...</p> : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['Nr. Contract', 'Bun imobil', 'Parte contractantă', 'Perioadă', 'Valoare', 'Status', ''].map((h) => (
                  <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.length === 0 && <tr><td colSpan={7} className="px-4 py-8 text-center text-gray-400">Nicio înregistrare.</td></tr>}
              {filtered.map((c) => (
                <tr key={c.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3 font-medium text-gray-800 text-xs">{c.numarContract}</td>
                  <td className="px-4 py-3 text-gray-700 text-xs">{c.propertyDenumire}</td>
                  <td className="px-4 py-3 text-gray-700 text-xs">{c.parteContractanta}</td>
                  <td className="px-4 py-3 text-gray-500 text-xs whitespace-nowrap">
                    {c.dataInceput ? new Date(c.dataInceput).toLocaleDateString('ro-RO') : '—'} →{' '}
                    {c.dataFinal   ? new Date(c.dataFinal  ).toLocaleDateString('ro-RO') : '—'}
                  </td>
                  <td className="px-4 py-3 text-gray-700 text-xs">{fmt(c.valoare)} {c.valutaMoneda}</td>
                  <td className="px-4 py-3"><span className={STATUS_CLS[c.status] || 'badge-inactiv'}>{c.status}</span></td>
                  <td className="px-4 py-3">
                    {isStaff && <button onClick={() => openEdit(c)} className="text-gray-400 hover:text-blue-700 text-xs px-2 py-1 rounded hover:bg-gray-100">Edit</button>}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {(modal === 'add' || modal === 'edit') && (
        <Modal title={modal === 'add' ? 'Adaugă contract' : 'Editează contract'} onClose={() => setModal(null)} size="lg">
          <form onSubmit={handleSave} className="space-y-4">
            {modal === 'add' && (
              <div>
                <label className="label">Bun imobil *</label>
                <select className="input" value={form.propertyId} onChange={(e) => {
                  const p = props.find((x) => x.id === e.target.value)
                  setForm((f) => ({ ...f, propertyId: e.target.value, propertyDenumire: p?.denumire || '' }))
                }} required>
                  <option value="">Selectează...</option>
                  {props.map((p) => <option key={p.id} value={p.id}>{p.denumire}</option>)}
                </select>
              </div>
            )}
            <div>
              <label className="label">Nr. contract *</label>
              <input className="input" value={form.numarContract} onChange={(e) => set('numarContract', e.target.value)} placeholder="CONTRACT-2024-001" required />
            </div>
            <div>
              <label className="label">Parte contractantă *</label>
              <input className="input" value={form.parteContractanta} onChange={(e) => set('parteContractanta', e.target.value)} required />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Data început *</label>
                <input className="input" type="date" value={form.dataInceput} onChange={(e) => set('dataInceput', e.target.value)} required />
              </div>
              <div>
                <label className="label">Data final *</label>
                <input className="input" type="date" value={form.dataFinal} onChange={(e) => set('dataFinal', e.target.value)} required />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Valoare *</label>
                <input className="input" type="number" step="0.01" min="0" value={form.valoare} onChange={(e) => set('valoare', e.target.value)} required />
              </div>
              <div>
                <label className="label">Monedă</label>
                <select className="input" value={form.valutaMoneda} onChange={(e) => set('valutaMoneda', e.target.value)}>
                  {['RON','EUR','USD'].map((m) => <option key={m}>{m}</option>)}
                </select>
              </div>
            </div>
            <div>
              <label className="label">Status</label>
              <select className="input" value={form.status} onChange={(e) => set('status', e.target.value)}>
                {STATUSES.map((s) => <option key={s}>{s}</option>)}
              </select>
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
