import { useEffect, useState } from 'react'
import api from '../services/api'
import { useAuth } from '../contexts/AuthContext'
import Modal from '../components/Modal'

const STATUSES = ['draft','publicata','activa','inchisa','atribuita','anulata','contestata']
const TYPES_ATTR = ['vanzare','inchiriere','concesionare']
const STATUS_CLS = {
  draft: 'badge-draft', publicata: 'badge-publicata', activa: 'badge-activa',
  inchisa: 'badge-inactiv', atribuita: 'badge-atribuita', anulata: 'badge-anulat', contestata: 'badge-inLitigiu',
}

const emptyForm = {
  propertyId: '', propertyDenumire: '', titlu: '', tipAtribuire: 'inchiriere',
  pretPornire: '', pasLicitare: '', garantieParticipare: '', dataInceput: '', dataFinal: '',
  status: 'draft', descriere: '',
}

export default function Auctions() {
  const { isStaff } = useAuth()
  const [data, setData]   = useState([])
  const [props, setProps] = useState([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState(null)
  const [form, setForm]   = useState(emptyForm)
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')

  const load = () => {
    setLoading(true)
    Promise.all([api.get('/auctions'), api.get('/properties')])
      .then(([a, p]) => { setData(a.data); setProps(p.data) })
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }))

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/auctions', {
        ...form,
        pretPornire:         parseFloat(form.pretPornire),
        pasLicitare:         parseFloat(form.pasLicitare),
        garantieParticipare: parseFloat(form.garantieParticipare),
      })
      setModal(null)
      load()
    } catch (e) { alert(e.message) } finally { setSaving(false) }
  }

  const fmt = (v) => parseFloat(v || 0).toLocaleString('ro-RO', { minimumFractionDigits: 2 })
  const fmtDate = (d) => d ? new Date(d).toLocaleDateString('ro-RO') : '—'

  const filtered = data.filter((a) =>
    search === '' ||
    a.titlu?.toLowerCase().includes(search.toLowerCase()) ||
    a.propertyDenumire?.toLowerCase().includes(search.toLowerCase())
  )

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900">Licitații Online</h1>
          <p className="text-sm text-gray-500">{data.length} licitații</p>
        </div>
        {isStaff && (
          <button onClick={() => { setForm(emptyForm); setModal('add') }} className="btn-primary">+ Adaugă licitație</button>
        )}
      </div>

      <input className="input max-w-xs" placeholder="Caută titlu, bun..." value={search} onChange={(e) => setSearch(e.target.value)} />

      {loading ? <p className="text-gray-400 text-sm">Se încarcă...</p> : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.length === 0 && <p className="text-gray-400 text-sm col-span-3">Nicio licitație.</p>}
          {filtered.map((a) => (
            <div key={a.id} className="card space-y-3">
              <div className="flex items-start justify-between gap-2">
                <h3 className="font-semibold text-gray-900 text-sm leading-snug line-clamp-2">{a.titlu}</h3>
                <span className={`${STATUS_CLS[a.status] || 'badge-inactiv'} flex-shrink-0`}>{a.status}</span>
              </div>
              <p className="text-xs text-gray-500 line-clamp-1">🏠 {a.propertyDenumire}</p>
              <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs text-gray-500">
                <span>Tip: <b className="text-gray-700 capitalize">{a.tipAtribuire}</b></span>
                <span>Preț pornire: <b className="text-gray-700">{fmt(a.pretPornire)} RON</b></span>
                <span>Pas: <b className="text-gray-700">{fmt(a.pasLicitare)} RON</b></span>
                <span>Garanție: <b className="text-gray-700">{fmt(a.garantieParticipare)} RON</b></span>
              </div>
              <div className="text-xs text-gray-400 border-t pt-2">
                📅 {fmtDate(a.dataInceput)} → {fmtDate(a.dataFinal)}
              </div>
              {a.castigatorNume && (
                <div className="bg-green-50 text-green-700 text-xs px-3 py-2 rounded-lg">
                  🏆 Câștigător: <b>{a.castigatorNume}</b> — {fmt(a.ofertaCastigatoare)} RON
                </div>
              )}
              {a.descriere && <p className="text-xs text-gray-400 line-clamp-2">{a.descriere}</p>}
            </div>
          ))}
        </div>
      )}

      {modal === 'add' && (
        <Modal title="Adaugă licitație" onClose={() => setModal(null)} size="lg">
          <form onSubmit={handleSave} className="space-y-4">
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
            <div>
              <label className="label">Titlul licitației *</label>
              <input className="input" value={form.titlu} onChange={(e) => set('titlu', e.target.value)} required />
            </div>
            <div>
              <label className="label">Tip atribuire *</label>
              <select className="input" value={form.tipAtribuire} onChange={(e) => set('tipAtribuire', e.target.value)}>
                {TYPES_ATTR.map((t) => <option key={t}>{t}</option>)}
              </select>
            </div>
            <div className="grid grid-cols-3 gap-3">
              <div>
                <label className="label">Preț pornire (RON) *</label>
                <input className="input" type="number" step="0.01" value={form.pretPornire} onChange={(e) => set('pretPornire', e.target.value)} required />
              </div>
              <div>
                <label className="label">Pas licitare *</label>
                <input className="input" type="number" step="0.01" value={form.pasLicitare} onChange={(e) => set('pasLicitare', e.target.value)} required />
              </div>
              <div>
                <label className="label">Garanție participare *</label>
                <input className="input" type="number" step="0.01" value={form.garantieParticipare} onChange={(e) => set('garantieParticipare', e.target.value)} required />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Data început *</label>
                <input className="input" type="datetime-local" value={form.dataInceput} onChange={(e) => set('dataInceput', e.target.value)} required />
              </div>
              <div>
                <label className="label">Data final *</label>
                <input className="input" type="datetime-local" value={form.dataFinal} onChange={(e) => set('dataFinal', e.target.value)} required />
              </div>
            </div>
            <div>
              <label className="label">Status</label>
              <select className="input" value={form.status} onChange={(e) => set('status', e.target.value)}>
                {STATUSES.map((s) => <option key={s}>{s}</option>)}
              </select>
            </div>
            <div>
              <label className="label">Descriere</label>
              <textarea className="input" rows={3} value={form.descriere} onChange={(e) => set('descriere', e.target.value)} />
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
