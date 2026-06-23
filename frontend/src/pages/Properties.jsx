import { useEffect, useState } from 'react'
import api from '../services/api'
import { useAuth } from '../contexts/AuthContext'
import Modal from '../components/Modal'

const TYPES    = ['teren', 'cladire', 'spatiu', 'constructie']
const DOMAINS  = ['public', 'privat']
const STATUSES = ['activ', 'inactiv', 'scosEvidenta', 'inLitigiu']

const empty = {
  denumire: '', tip: 'teren', adresa: '', localitate: '', domeniuJuridic: 'public',
  numarCadastral: '', numarCarteF: '', suprafata: '', valoareInventar: '',
  destinatie: '', status: 'activ', descriere: '',
}

export default function Properties() {
  const { isStaff, isAdmin } = useAuth()
  const [data, setData]     = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError]   = useState('')
  const [modal, setModal]   = useState(null) // null | 'add' | 'edit' | 'view'
  const [selected, setSelected] = useState(null)
  const [form, setForm]     = useState(empty)
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')
  const [filterTip, setFilterTip] = useState('')

  const load = () => {
    setLoading(true)
    api.get('/properties', { params: filterTip ? { tip: filterTip } : {} })
      .then((r) => setData(r.data))
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [filterTip])

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }))

  const openAdd = () => { setForm(empty); setModal('add') }
  const openEdit = (p) => {
    setSelected(p)
    setForm({
      denumire: p.denumire, tip: p.tip, adresa: p.adresa, localitate: p.localitate,
      domeniuJuridic: p.domeniuJuridic, numarCadastral: p.numarCadastral,
      numarCarteF: p.numarCarteF, suprafata: p.suprafata, valoareInventar: p.valoareInventar,
      destinatie: p.destinatie, status: p.status, descriere: p.descriere || '',
    })
    setModal('edit')
  }
  const openView = (p) => { setSelected(p); setModal('view') }

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      const payload = {
        ...form,
        suprafata: parseFloat(form.suprafata),
        valoareInventar: parseFloat(form.valoareInventar),
      }
      if (modal === 'add') {
        await api.post('/properties', payload)
      } else {
        await api.put(`/properties/${selected.id}`, payload)
      }
      setModal(null)
      load()
    } catch (e) {
      alert(e.message)
    } finally {
      setSaving(false)
    }
  }

  const handleDelete = async (p) => {
    if (!confirm(`Scoateți din evidență "${p.denumire}"?`)) return
    try {
      await api.delete(`/properties/${p.id}`)
      load()
    } catch (e) { alert(e.message) }
  }

  const filtered = data.filter((p) =>
    search === '' ||
    p.denumire?.toLowerCase().includes(search.toLowerCase()) ||
    p.adresa?.toLowerCase().includes(search.toLowerCase()) ||
    p.localitate?.toLowerCase().includes(search.toLowerCase())
  )

  const formatRON = (v) => parseFloat(v || 0).toLocaleString('ro-RO', { minimumFractionDigits: 2 })

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900">Bunuri Imobile</h1>
          <p className="text-sm text-gray-500">{data.length} bunuri înregistrate</p>
        </div>
        {isStaff && (
          <button onClick={openAdd} className="btn-primary flex items-center gap-2">
            + Adaugă bun
          </button>
        )}
      </div>

      {/* Filtre */}
      <div className="flex gap-3 flex-wrap">
        <input
          className="input max-w-xs"
          placeholder="Caută denumire, adresă..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <select className="input max-w-[160px]" value={filterTip} onChange={(e) => setFilterTip(e.target.value)}>
          <option value="">Toate tipurile</option>
          {TYPES.map((t) => <option key={t}>{t}</option>)}
        </select>
      </div>

      {error && <div className="text-red-600 text-sm">{error}</div>}

      {loading ? (
        <div className="text-gray-400 text-sm">Se încarcă...</div>
      ) : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['Denumire', 'Tip', 'Localitate', 'Suprafață (mp)', 'Valoare inventar', 'Status', ''].map((h) => (
                  <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.length === 0 && (
                <tr><td colSpan={7} className="px-4 py-8 text-center text-gray-400">Nicio înregistrare.</td></tr>
              )}
              {filtered.map((p) => (
                <tr key={p.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <p className="font-medium text-gray-800">{p.denumire}</p>
                    <p className="text-xs text-gray-400">{p.adresa}</p>
                  </td>
                  <td className="px-4 py-3 capitalize text-gray-600">{p.tip}</td>
                  <td className="px-4 py-3 text-gray-600">{p.localitate}</td>
                  <td className="px-4 py-3 text-gray-600">{parseFloat(p.suprafata || 0).toLocaleString('ro-RO')}</td>
                  <td className="px-4 py-3 text-gray-600">{formatRON(p.valoareInventar)} RON</td>
                  <td className="px-4 py-3"><StatusBadge status={p.status} /></td>
                  <td className="px-4 py-3">
                    <div className="flex gap-2">
                      <button onClick={() => openView(p)} className="text-gray-400 hover:text-primary-700 text-xs px-2 py-1 rounded hover:bg-gray-100">Detalii</button>
                      {isStaff && <button onClick={() => openEdit(p)} className="text-gray-400 hover:text-blue-700 text-xs px-2 py-1 rounded hover:bg-gray-100">Edit</button>}
                      {isAdmin && <button onClick={() => handleDelete(p)} className="text-gray-400 hover:text-red-600 text-xs px-2 py-1 rounded hover:bg-gray-100">Șterge</button>}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* Modal adăugare/editare */}
      {(modal === 'add' || modal === 'edit') && (
        <Modal title={modal === 'add' ? 'Adaugă bun imobil' : 'Editează bun imobil'} onClose={() => setModal(null)} size="lg">
          <form onSubmit={handleSave} className="space-y-4">
            <div>
              <label className="label">Denumire *</label>
              <input className="input" value={form.denumire} onChange={(e) => set('denumire', e.target.value)} required />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Tip *</label>
                <select className="input" value={form.tip} onChange={(e) => set('tip', e.target.value)}>
                  {TYPES.map((t) => <option key={t}>{t}</option>)}
                </select>
              </div>
              <div>
                <label className="label">Domeniu juridic *</label>
                <select className="input" value={form.domeniuJuridic} onChange={(e) => set('domeniuJuridic', e.target.value)}>
                  {DOMAINS.map((d) => <option key={d}>{d}</option>)}
                </select>
              </div>
            </div>
            <div>
              <label className="label">Adresă *</label>
              <input className="input" value={form.adresa} onChange={(e) => set('adresa', e.target.value)} required />
            </div>
            <div>
              <label className="label">Localitate *</label>
              <input className="input" value={form.localitate} onChange={(e) => set('localitate', e.target.value)} required />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Nr. Cadastral *</label>
                <input className="input" value={form.numarCadastral} onChange={(e) => set('numarCadastral', e.target.value)} required />
              </div>
              <div>
                <label className="label">Nr. Carte Funciară *</label>
                <input className="input" value={form.numarCarteF} onChange={(e) => set('numarCarteF', e.target.value)} required />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="label">Suprafață (mp) *</label>
                <input className="input" type="number" step="0.01" value={form.suprafata} onChange={(e) => set('suprafata', e.target.value)} required />
              </div>
              <div>
                <label className="label">Valoare inventar (RON) *</label>
                <input className="input" type="number" step="0.01" value={form.valoareInventar} onChange={(e) => set('valoareInventar', e.target.value)} required />
              </div>
            </div>
            <div>
              <label className="label">Destinație *</label>
              <input className="input" value={form.destinatie} onChange={(e) => set('destinatie', e.target.value)} required />
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

      {/* Modal detalii */}
      {modal === 'view' && selected && (
        <Modal title="Detalii bun imobil" onClose={() => setModal(null)} size="lg">
          <div className="grid grid-cols-2 gap-x-6 gap-y-3 text-sm">
            {[
              ['Denumire', selected.denumire],
              ['Tip', selected.tip],
              ['Adresă', selected.adresa],
              ['Localitate', selected.localitate],
              ['Domeniu juridic', selected.domeniuJuridic],
              ['Nr. Cadastral', selected.numarCadastral],
              ['Nr. Carte Funciară', selected.numarCarteF],
              ['Suprafață', `${parseFloat(selected.suprafata || 0).toLocaleString('ro-RO')} mp`],
              ['Valoare inventar', `${parseFloat(selected.valoareInventar || 0).toLocaleString('ro-RO', { minimumFractionDigits: 2 })} RON`],
              ['Destinație', selected.destinatie],
              ['Status', selected.status],
            ].map(([l, v]) => (
              <div key={l}>
                <p className="text-gray-400 text-xs">{l}</p>
                <p className="font-medium text-gray-800 capitalize">{v}</p>
              </div>
            ))}
            {selected.descriere && (
              <div className="col-span-2">
                <p className="text-gray-400 text-xs">Descriere</p>
                <p className="font-medium text-gray-800">{selected.descriere}</p>
              </div>
            )}
          </div>
        </Modal>
      )}
    </div>
  )
}

function StatusBadge({ status }) {
  const cls = {
    activ: 'badge-activ', inactiv: 'badge-inactiv',
    scosEvidenta: 'badge-expirat', inLitigiu: 'badge-inLitigiu',
  }
  return <span className={cls[status] || 'badge-inactiv'}>{status}</span>
}
