import axios from 'axios'
import { auth } from '../firebase'

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL + '/api',
  timeout: 15000,
})

// Atașează automat Firebase ID token la fiecare request
api.interceptors.request.use(async (config) => {
  const user = auth.currentUser
  if (user) {
    const token = await user.getIdToken()
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Handling global errors
api.interceptors.response.use(
  (res) => res,
  (err) => {
    const msg = err.response?.data?.error || err.message || 'Eroare necunoscută'
    return Promise.reject(new Error(msg))
  }
)

export default api
