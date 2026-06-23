import { useEffect, useState } from 'react'
import api from '../services/api'
import { useAuth } from '../contexts/AuthContext'
import Modal from '../components/Modal'

const ROLES    = ['administrator','functionar','extern']
const STATUSES = ['activ','inactiv','suspendat']
const ROLE_CLS = { administrator: 'badge-atribuita', functionar: 'badge-activ', extern: 'badge-draft' }
const STATUS_CLS = { activ: 'badge-activ', inactiv: 'badge-inactiv', suspendat: 'badge-anulat' }

export default function Users() {
  const { isAdmin } = useAuth()
  const [data, setData] = useState([])
  const [loading, setLoading] = useState(true)
  const [modal, setModal] = useState(null) // null | 'add'
  const [form, setForm]   = useState({ email: '', password: '', firstName: '', lastName: '', phone: '', role: 'extern', departament: '' })
  const [saving, setSaving] = useState(false)
  const [search, setSearch] = useState('')

  const load = () => {
    setLoading(true)
    api.get('/users')
      .then((r) => setData(r.data))
      .catch(() => {})
      .finally(() => setLoading(false))
  }

  useEffect(() => { load() }, [])

  const set = (k, v) => setForm((f) => ({ ...f, [k]: v }))

  const handleSave = async (e) => {
    e.preventDefault()
    setSaving(true)
    try {
      await api.post('/users/register', form)
      setModal(null)
      load()
    } catch (e) { alert(e.message) } finally { setSaving(false) }
  }

  const updateRole = async (uid, role) => {
    try { await api.put(`/users/${uid}/role`, { role }); load() } catch (e) { alert(e.message) }
  }

  const updateStatus = async (uid, status) => {
    if (!confirm(`Schimbi statusul la "${status}"?`)) return
    try { await api.put(`/users/${uid}/status`, { status }); load() } catch (e) { alert(e.message) }
  }

  const filtered = data.filter((u) =>
    search === '' ||
    u.email?.toLowerCase().includes(search.toLowerCase()) ||
    `${u.firstName} ${u.lastName}`.toLowerCase().includes(search.toLowerCase())
  )

  if (!isAdmin) return <div className="p-8 text-gray-400">Acces restricționat — doar administratori.</div>

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between flex-wrap gap-3">
        <div>
          <h1 className="text-xl font-bold text-gray-900">Utilizatori</h1>
          <p className="text-sm text-gray-500">{data.length} utilizatori</p>
        </div>
        <button onClick={() => { setForm({ email: '', password: '', firstName: '', lastName: '', phone: '', role: 'extern', departament: '' }); setModal('add') }} className="btn-primary">
          + Adaugă utilizator
        </button>
      </div>

      <input className="input max-w-xs" placeholder="Caută email, nume..." value={search} onChange={(e) => setSearch(e.target.value)} />

      {loading ? <p className="text-gray-400 text-sm">Se încarcă...</p> : (
        <div className="card p-0 overflow-hidden">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-200">
              <tr>
                {['Utilizator', 'Email', 'Departament', 'Rol', 'Status', 'Acțiuni'].map((h) => (
                  <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {filtered.length === 0 && <tr><td colSpan={6} className="px-4 py-8 text-center text-gray-400">Niciun utilizator.</td></tr>}
              {filtered.map((u) => (
                <tr key={u.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-full bg-primary-100 text-primary-700 flex items-center justify-center text-sm font-bold flex-shrink-0">
                        {(u.firstName || u.email || '?')[0].toUpperCase()}
                      </div>
                      <div>
                        <p className="font-medium text-gray-800">{u.firstName} {u.lastName}</p>
                        <p className="text-xs text-gray-400">{new Date(u.createdAt).toLocaleDateString('ro-RO')}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-4 py-3 text-gray-600 text-xs">{u.email}</td>
                  <td className="px-4 py-3 text-gray-500 text-xs">{u.departament || '—'}</td>
                  <td className="px-4 py-3">
                    <select
                      className="text-xs border border-gray-200 rounded px-2 py-1"
                      value={u.role}
                      onChange={(e) => updateRole(u.id, e.target.value)}
                    >
                      {ROLES.map((r) => <option key={r}>{r}</option>)}
                    </select>
                  </td>
                  <td className="px-4 py-3"><span className={STATUS_CLS[u.status] || 'badge-inactiv'}>{u.status}</span></td>
                  <td className="px-4 py-3">
                    <select
                      className="text-xs border border-gray-200 rounded px-2 py-1"
                      value={u.status}
                      onChange={(e) => updateStatus(u.id, e.target.value)}
                    >
                      {STATUSES.map((s) => <option key={s}>{s}</option>)}
                    </select>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {modal === 'add' && (
        <Modal title="Adaugă utilizator" onClose={() => setModal(null)} size="md">
          <form onSubmit={handleSave} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="label">Prenume *</label>
                <input className="input" value={form.firstName} onChange={(e) => set('firstName', e.target.value)} required />
              </div>
              <div>
                <label className="label">Nume *</label>
                <input className="input" value={form.lastName} onChange={(e) => set('lastName', e.target.value)} required />
              </div>
            </div>
            <div>
              <label className="label">Email *</label>
              <input className="input" type="email" value={form.email} onChange={(e) => set('email', e.target.value)} required />
            </div>
            <div>
              <label className="label">Parolă *</label>
              <input className="input" type="password" value={form.password} onChange={(e) => set('password', e.target.value)} required minLength={8} placeholder="Minim 8 caractere" />
            </div>
            <div>
              <label className="label">Telefon</label>
              <input className="input" value={form.phone} onChange={(e) => set('phone', e.target.value)} />
            </div>
            <div>
              <label className="label">Departament</label>
              <input className="input" value={form.departament} onChange={(e) => set('departament', e.target.value)} />
            </div>
            <div>
              <label className="label">Rol</label>
              <select className="input" value={form.role} onChange={(e) => set('role', e.target.value)}>
                {ROLES.map((r) => <option key={r}>{r}</option>)}
              </select>
            </div>
            <div className="flex gap-3 pt-2">
              <button type="submit" className="btn-primary" disabled={saving}>{saving ? 'Se creează...' : 'Creează cont'}</button>
              <button type="button" className="btn-secondary" onClick={() => setModal(null)}>Anulează</button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  )
}
