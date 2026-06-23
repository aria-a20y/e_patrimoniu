import { useEffect, useState } from 'react'
import api from '../services/api'
import { useAuth } from '../contexts/AuthContext'
import Modal from '../components/Modal'

const DOC_TYPES = ['hcl','extrasCF','planCadastral','raportEvaluare','contract','procesVerbal','actAditional','documentPlata','altele']
const STATUSES  = ['neverificat','inVerificare','verificat','respins']
const STATUS_CLS = {
  neverificat: 'badge-draft', inVerificare: 'badge-publicata',
  verificat: 'badge-activ', respins: 'badge-anulat',
}
const ICONS = {
  hcl: '📋', extrasCF: '📑', planCadastral: '🗺', raportEvaluare: '📊',
  contract: '📄', procesVerbal: '📝', actAditional: '📎', documentPlata: '💳', altele: '📁',
}

export default function Documents() {
  const { isStaff } = useAuth()
  const [data, setData]   = useState([])
  const [props, setProps] = useState([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState(null)
  const [form, setForm]   = useState({ denumire: '', tip: DOC_TYPES[0], propertyId: '', numarDocument: '', dataDocument: '', emitent: '', fileUrl: '', note: '' })
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')

  const load = () => {
    setLoading(true)
    Promise.all([api.get('/documents'), api.get('/properties')])
      .then(([d, p]) => { setData(d.data); setProps(p.data) })
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }))

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/documents', form)
      setModal(null)
      load()
    } catch (e) { alert(e.message) } finally { setSaving(false) }
  }

  const updateStatus = async (id, status) => {
    try {
      await api.put(`/documents/${id}/status`, { status })
      load()
    } catch (e) { alert(e.message) }
  }

  const filtered = data.filter((d) =>
    search === '' ||
    d.denumire?.toLowerCase().includes(search.toLowerCase()) ||
    d.tip?.toLowerCase().includes(search.toLowerCase()) ||
    d.emitent?.toLowerCase().includes(search.toLowerCase())
  )

  const fmtDate = (d) => d ? new Date(d).toLocaleDateString('ro-RO') : '—'

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900">Documente</h1>
          <p className="text-sm text-gray-500">{data.length} documente</p>
        </div>
        {isStaff && (
          <button onClick={() => { setForm({ denumire: '', tip: DOC_TYPES[0], propertyId: '', numarDocument: '', dataDocument: '', emitent: '', fileUrl: '', note: '' }); setModal('add') }} className="btn-primary">
            + Adaugă document
          </button>
        )}
      </div>

      <input className="input max-w-xs" placeholder="Caută denumire, tip, emitent..." value={search} onChange={(e) => setSearch(e.target.value)} />

      {loading ? <p className="text-gray-400 text-sm">Se încarcă...</p> : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          {filtered.length === 0 && <p className="text-gray-400 text-sm col-span-3">Nicio înregistrare.</p>}
          {filtered.map((d) => (
            <div key={d.id} className="card space-y-3">
              <div className="flex items-start justify-between gap-2">
                <div className="flex items-center gap-2">
                  <span className="text-2xl">{ICONS[d.tip] || '📁'}</span>
                  <div>
                    <p className="font-semibold text-sm text-gray-900 line-clamp-2">{d.denumire}</p>
                    <p className="text-xs text-gray-400 capitalize">{d.tip}</p>
                  </div>
                </div>
                <span className={`${STATUS_CLS[d.status] || 'badge-inactiv'} flex-shrink-0`}>{d.status}</span>
              </div>

              {d.propertyId && (
                <p className="text-xs text-gray-500">🏠 {props.find((p) => p.id === d.propertyId)?.denumire || d.propertyId}</p>
              )}

              <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs text-gray-500">
                {d.numarDocument && <span>Nr: <b className="text-gray-700">{d.numarDocument}</b></span>}
                {d.dataDocument  && <span>Data: <b className="text-gray-700">{fmtDate(d.dataDocument)}</b></span>}
                {d.emitent       && <span className="col-span-2">Emitent: <b className="text-gray-700">{d.emitent}</b></span>}
              </div>

              <div className="flex items-center gap-2 pt-1">
                {d.fileUrl && (
                  <a href={d.fileUrl} target="_blank" rel="noreferrer" className="text-xs text-primary-700 hover:underline">
                    📥 Descarcă
                  </a>
                )}
                {isStaff && (
                  <select
                    className="ml-auto text-xs border border-gray-200 rounded px-2 py-1"
                    value={d.status}
                    onChange={(e) => updateStatus(d.id, e.target.value)}
                  >
                    {STATUSES.map((s) => <option key={s}>{s}</option>)}
                  </select>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {modal === 'add' && (
        <Modal title="Adaugă document" onClose={() => setModal(null)} size="lg">
          <form onSubmit={handleSave} className="space-y-4">
            <div>
              <label className="label">Denumire document *</label>
              <input className="input" value={form.denumire} onChange={(e) => set('denumire', e.target.value)} required />
            </div>
            <div>
              <label className="label">Tip document *</label>
              <select className="input" value={form.tip} onChange={(e) => set('tip', e.target.value)}>
                {DOC_TYPES.map((t) => <option key={t}>{t}</option>)}
              </select>
            </div>
            <div>
              <label className="label">Bun imobil asociat</label>
              <select className="input" value={form.propertyId} onChange={(e) => set('propertyId', e.target.value)}>
                <option value="">— Fără asociere —</option>
                {props.map((p) => <option key={p.id} value={p.id}>{p.denumire}</option>)}
              </select>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Nr. document</label>
                <input className="input" value={form.numarDocument} onChange={(e) => set('numarDocument', e.target.value)} />
              </div>
              <div>
                <label className="label">Data document</label>
                <input className="input" type="date" value={form.dataDocument} onChange={(e) => set('dataDocument', e.target.value)} />
              </div>
            </div>
            <div>
              <label className="label">Emitent</label>
              <input className="input" value={form.emitent} onChange={(e) => set('emitent', e.target.value)} />
            </div>
            <div>
              <label className="label">URL fișier (link stocare)</label>
              <input className="input" type="url" value={form.fileUrl} onChange={(e) => set('fileUrl', e.target.value)} placeholder="https://..." />
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
