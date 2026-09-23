import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import { useAuthStore } from './store/authStore';

// Components
import Navbar from './components/Navbar';

// Pages
import Landing from './pages/Landing';
import Register from './pages/Register';
import Login from './pages/Login';
import PetaniDashboard from './pages/PetaniDashboard';
import AdminDashboard from './pages/AdminDashboard';
import PPLDashboard from './pages/PPLDashboard';
import QRScannerKiosk from './pages/QRScannerKiosk';

// Protected Route Guard
function ProtectedRoute({ children, allowedRoles }) {
  const { isAuthenticated, user, isLoading } = useAuthStore();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <div className="w-8 h-8 border-4 border-emerald-600 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAuthenticated || !user) {
    return <Navigate to="/login" replace />;
  }

  if (allowedRoles && !allowedRoles.includes(user.role)) {
    // Redirect to their respective dashboard
    if (user.role === 'ADMIN') return <Navigate to="/admin" replace />;
    if (user.role === 'PPL') return <Navigate to="/ppl" replace />;
    return <Navigate to="/petani" replace />;
  }

  return children;
}

// App Layout with Navbar
function DashboardLayout({ children }) {
  return (
    <div className="min-h-screen bg-slate-50 flex flex-col font-sans">
      <Navbar />
      <main className="flex-1 max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8 pt-6">
        {children}
      </main>
    </div>
  );
}

// Root redirector
function RootRedirect() {
  const { isAuthenticated, user, isLoading } = useAuthStore();

  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <div className="w-8 h-8 border-4 border-emerald-600 border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

  if (!isAuthenticated || !user) {
    return <Navigate to="/login" replace />;
  }

  if (user.role === 'ADMIN') return <Navigate to="/admin" replace />;
  if (user.role === 'PPL') return <Navigate to="/ppl" replace />;
  return <Navigate to="/petani" replace />;
}

export default function App() {
  const { initAuth } = useAuthStore();

  useEffect(() => {
    initAuth();
  }, [initAuth]);

  return (
    <BrowserRouter>
      <Toaster position="top-right" />
      <Routes>
        {/* Landing Page */}
        <Route path="/" element={<Landing />} />

        {/* Public Login & Register Routes */}
        <Route path="/login" element={<Login />} />
        <Route path="/login/:portalRole" element={<Login />} />
        <Route path="/register" element={<Register />} />

        {/* Kiosk Scanner Route */}
        <Route path="/kiosk-scanner" element={<QRScannerKiosk />} />

        {/* Petani Dashboard Route */}
        <Route
          path="/petani"
          element={
            <ProtectedRoute allowedRoles={['PETANI', 'ADMIN']}>
              <DashboardLayout>
                <PetaniDashboard />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />

        {/* Admin Dashboard Route */}
        <Route
          path="/admin"
          element={
            <ProtectedRoute allowedRoles={['ADMIN']}>
              <DashboardLayout>
                <AdminDashboard />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />

        {/* PPL Dashboard Route */}
        <Route
          path="/ppl"
          element={
            <ProtectedRoute allowedRoles={['PPL', 'ADMIN']}>
              <DashboardLayout>
                <PPLDashboard />
              </DashboardLayout>
            </ProtectedRoute>
          }
        />

        {/* Fallback Redirect */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </BrowserRouter>
  );
}
