import { NavLink } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

const navItems = [
  { to: '/dashboard',    label: 'Dashboard',        icon: '⊞' },
  { to: '/properties',   label: 'Bunuri Imobile',   icon: '⌂' },
  { to: '/transactions', label: 'Tranzacții',        icon: '⇄' },
  { to: '/contracts',    label: 'Contracte',         icon: '📄' },
  { to: '/auctions',     label: 'Licitații Online',  icon: '⚖' },
  { to: '/documents',    label: 'Documente',         icon: '📁' },
]

const adminItems = [
  { to: '/users', label: 'Utilizatori', icon: '👥' },
  { to: '/audit', label: 'Jurnal Audit', icon: '🔍' },
]

export default function Sidebar({ collapsed, onToggle }) {
  const { userName, profile, logout } = useAuth()

  return (
    <aside
      className={`flex flex-col bg-primary-700 text-white transition-all duration-300 ${
        collapsed ? 'w-16' : 'w-64'
      } min-h-screen flex-shrink-0`}
    >
      {/* Logo */}
      <div className="flex items-center justify-between px-4 py-5 border-b border-primary-600">
        {!collapsed && (
          <div className="flex items-center gap-2">
            <span className="text-2xl">🏛</span>
            <span className="font-bold text-lg leading-tight">e-Patrimoniu</span>
          </div>
        )}
        {collapsed && <span className="text-2xl mx-auto">🏛</span>}
        <button
          onClick={onToggle}
          className="text-white/70 hover:text-white p-1 rounded transition-colors"
          title={collapsed ? 'Extinde' : 'Restrânge'}
        >
          {collapsed ? '›' : '‹'}
        </button>
      </div>

      {/* Navigare */}
      <nav className="flex-1 py-4 space-y-0.5 overflow-y-auto">
        {navItems.map((item) => (
          <NavLink
            key={item.to}
            to={item.to}
            className={({ isActive }) =>
              `flex items-center gap-3 px-4 py-2.5 text-sm transition-colors ${
                isActive
                  ? 'bg-primary-800 text-white font-semibold'
                  : 'text-white/80 hover:bg-primary-600 hover:text-white'
              }`
            }
            title={collapsed ? item.label : ''}
          >
            <span className="text-lg flex-shrink-0 w-5 text-center">{item.icon}</span>
            {!collapsed && <span>{item.label}</span>}
          </NavLink>
        ))}

        {profile?.role === 'administrator' && (
          <>
            {!collapsed && (
              <p className="px-4 pt-4 pb-1 text-xs font-semibold text-white/40 uppercase tracking-wider">
                Administrare
              </p>
            )}
            {collapsed && <div className="border-t border-primary-600 my-2" />}
            {adminItems.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                className={({ isActive }) =>
                  `flex items-center gap-3 px-4 py-2.5 text-sm transition-colors ${
                    isActive
                      ? 'bg-primary-800 text-white font-semibold'
                      : 'text-white/80 hover:bg-primary-600 hover:text-white'
                  }`
                }
                title={collapsed ? item.label : ''}
              >
                <span className="text-lg flex-shrink-0 w-5 text-center">{item.icon}</span>
                {!collapsed && <span>{item.label}</span>}
              </NavLink>
            ))}
          </>
        )}
      </nav>

      {/* User footer */}
      <div className="border-t border-primary-600 p-4">
        {!collapsed ? (
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-full bg-primary-500 flex items-center justify-center text-sm font-bold flex-shrink-0">
              {(userName || 'U')[0].toUpperCase()}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{userName}</p>
              <p className="text-xs text-white/60 truncate capitalize">{profile?.role || 'extern'}</p>
            </div>
            <button
              onClick={logout}
              className="text-white/60 hover:text-white p-1 rounded transition-colors"
              title="Deconectare"
            >
              ⏻
            </button>
          </div>
        ) : (
          <button
            onClick={logout}
            className="w-full text-white/60 hover:text-white text-xl text-center transition-colors"
            title="Deconectare"
          >
            ⏻
          </button>
        )}
      </div>
    </aside>
  )
}
