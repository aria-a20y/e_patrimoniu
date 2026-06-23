import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider } from './contexts/AuthContext'
import ProtectedRoute from './components/ProtectedRoute'
import Layout from './components/Layout'
import Login from './pages/Login'
import Dashboard from './pages/Dashboard'
import Properties from './pages/Properties'
import Transactions from './pages/Transactions'
import Contracts from './pages/Contracts'
import Auctions from './pages/Auctions'
import Documents from './pages/Documents'
import Users from './pages/Users'
import AuditLog from './pages/AuditLog'

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route element={<ProtectedRoute />}>
            <Route element={<Layout />}>
              <Route index element={<Navigate to="/dashboard" replace />} />
              <Route path="/dashboard"    element={<Dashboard />} />
              <Route path="/properties"   element={<Properties />} />
              <Route path="/transactions" element={<Transactions />} />
              <Route path="/contracts"    element={<Contracts />} />
              <Route path="/auctions"     element={<Auctions />} />
              <Route path="/documents"    element={<Documents />} />
              <Route path="/users"        element={<Users />} />
              <Route path="/audit"        element={<AuditLog />} />
            </Route>
          </Route>
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  )
}
