import { createContext, useContext, useEffect, useState } from 'react'
import { onAuthStateChanged, signOut } from 'firebase/auth'
import { auth } from '../firebase'
import api from '../services/api'

const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser]       = useState(null)   // Firebase user
  const [profile, setProfile] = useState(null)   // PostgreSQL profile (role, status etc.)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        setUser(firebaseUser)
        try {
          // Cere profilul din backend (auto-creare dacă nu există)
          const { data } = await api.get('/users/me')
          setProfile(data)
        } catch {
          setProfile(null)
        }
      } else {
        setUser(null)
        setProfile(null)
      }
      setLoading(false)
    })
    return unsubscribe
  }, [])

  const logout = () => signOut(auth)

  const isAdmin  = profile?.role === 'administrator'
  const isStaff  = profile?.role === 'functionar' || profile?.role === 'administrator'
  const userName = profile
    ? `${profile.firstName || ''} ${profile.lastName || ''}`.trim() || user?.email
    : user?.email

  return (
    <AuthContext.Provider value={{ user, profile, loading, logout, isAdmin, isStaff, userName }}>
      {children}
    </AuthContext.Provider>
  )
}

export function useAuth() {
  return useContext(AuthContext)
}
