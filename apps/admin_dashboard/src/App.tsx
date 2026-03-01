import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import {
  Users,
  Video,
  Gift,
  AlertOctagon,
  LayoutDashboard,
  FileText,
  Settings,
  TrendingUp,
  ShieldCheck,
  Search,
  Bell,
  MoreVertical,
  DollarSign
} from 'lucide-react'

// --- Mock Stats until backend is running ---
const defaultStats = {
  total_users: 1240,
  total_videos: 8420,
  total_tokens: 450000,
  total_gifts: 3200,
  pending_reports: 14
}

const App = () => {
  const [activeTab, setActiveTab] = useState('Dashboard')
  const [stats, setStats] = useState(defaultStats)
  const [reports, setReports] = useState<any[]>([])
  const [transactions, setTransactions] = useState<any[]>([])

  useEffect(() => {
    fetchStats()
    fetchReports()
    fetchTransactions()
  }, [])

  const fetchStats = async () => {
    try {
      const res = await fetch('http://localhost:8080/api/admin/stats')
      if (res.ok) {
        const data = await res.json()
        setStats(data)
      }
    } catch (e) {
      console.warn("Using mock stats - backend unavailable")
    }
  }

  const fetchReports = async () => {
    try {
      const res = await fetch('http://localhost:8080/api/admin/reports?limit=10')
      if (res.ok) setReports(await res.json())
    } catch (e) {
      console.warn("Using mock reports")
    }
  }

  const fetchTransactions = async () => {
    try {
      const res = await fetch('http://localhost:8080/api/admin/transactions?limit=15')
      if (res.ok) setTransactions(await res.json())
    } catch (e) {
      console.warn("Using mock transactions")
    }
  }

  return (
    <div style={{ display: 'flex' }}>
      {/* Sidebar */}
      <div className="sidebar shadow-2xl">
        <div style={{ fontSize: '1.4rem', fontWeight: 900, marginBottom: '40px', display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{ width: '32px', height: '32px', background: 'linear-gradient(135deg, #ff00e5, #7000ff)', borderRadius: '8px', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <ShieldCheck size={18} color="white" />
          </div>
          GIPJAZES <span style={{ color: 'var(--brand-primary)', fontSize: '0.8rem', background: 'rgba(255,0,229,0.1)', padding: '2px 8px', borderRadius: '4px', marginLeft: '4px' }}>ADMIN</span>
        </div>

        <nav style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
          <SidebarItem icon={<LayoutDashboard size={20} />} label="Dashboard" active={activeTab === 'Dashboard'} onClick={() => setActiveTab('Dashboard')} />
          <SidebarItem icon={<FileText size={20} />} label="Reports" active={activeTab === 'Reports'} onClick={() => setActiveTab('Reports')} />
          <SidebarItem icon={<Users size={20} />} label="Users" active={activeTab === 'Users'} onClick={() => setActiveTab('Users')} />
          <SidebarItem icon={<DollarSign size={20} />} label="Economy" active={activeTab === 'Economy'} onClick={() => setActiveTab('Economy')} />
          <SidebarItem icon={<Settings size={20} />} label="Settings" active={activeTab === 'Settings'} onClick={() => setActiveTab('Settings')} />
        </nav>

        <div style={{ marginTop: 'auto', padding: '20px', background: 'rgba(255,255,255,0.03)', borderRadius: '15px', border: '1px solid rgba(255,255,255,0.05)' }}>
          <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)', marginBottom: '8px' }}>SYSTEM HEALTH</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
            <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#00ff8b', boxShadow: '0 0 10px #00ff8b' }} />
            <span style={{ fontSize: '0.9rem', fontWeight: 600 }}>All Systems Operational</span>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <main className="main-content">
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '40px' }}>
          <div>
            <h1 style={{ fontSize: '2rem', fontWeight: 900, marginBottom: '4px' }}>{activeTab} Overview</h1>
            <p style={{ color: 'var(--text-muted)' }}>Welcome back, Operator. Here's what's happening on GIPJAZES V.</p>
          </div>
          <div style={{ display: 'flex', gap: '15px', alignItems: 'center' }}>
            <div style={{ position: 'relative' }}>
              <input
                type="text"
                placeholder="Search resources..."
                style={{ background: 'var(--bg-card)', border: '1px solid var(--border-color)', borderRadius: '12px', padding: '10px 15px 10px 40px', color: 'white', width: '240px', outline: 'none' }}
              />
              <Search size={16} color="var(--text-muted)" style={{ position: 'absolute', left: '15px', top: '50%', transform: 'translateY(-50%)' }} />
            </div>
            <div style={{ width: '42px', height: '42px', borderRadius: '12px', background: 'var(--bg-card)', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', position: 'relative' }}>
              <Bell size={20} color="white" />
              <div style={{ position: 'absolute', top: '10px', right: '10px', width: '8px', height: '8px', background: 'red', borderRadius: '50%', border: '2px solid var(--bg-card)' }} />
            </div>
          </div>
        </header>

        {activeTab === 'Dashboard' && (
          <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: '24px', marginBottom: '40px' }}>
              <StatCard title="Total Creators" value={stats.total_users.toLocaleString()} icon={<Users color="#7000ff" />} growth="+12%" />
              <StatCard title="Videos Hosted" value={stats.total_videos.toLocaleString()} icon={<Video color="#ff004c" />} growth="+24%" />
              <StatCard title="Gift Transactions" value={stats.total_gifts.toLocaleString()} icon={<Gift color="#ffaa00" />} growth="+18%" />
              <StatCard title="Economy Pool" value={`$${(stats.total_tokens).toLocaleString()}`} icon={<DollarSign color="#00ff8b" />} growth="+5%" />
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>
              <div className="glass shadow-2xl" style={{ padding: '30px', borderRadius: '24px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '30px' }}>
                  <h3 style={{ fontSize: '1.2rem', fontWeight: 800 }}>Platform Reports</h3>
                  <button style={{ border: 'none', background: 'none', color: 'var(--brand-primary)', fontWeight: 700, cursor: 'pointer' }}>View All</button>
                </div>
                <div style={{ minHeight: '300px' }}>
                  {reports.length > 0 ? (
                    <table style={{ width: '100%' }}>
                      <thead>
                        <tr>
                          <th>Reporter</th>
                          <th>Reason</th>
                          <th>Status</th>
                          <th>Time</th>
                          <th>Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        {reports.map((r, i) => (
                          <tr key={i}>
                            <td><span style={{ fontWeight: 700 }}>{r.reporter || 'Anonymous'}</span></td>
                            <td>{r.reason}</td>
                            <td><span className={`status-badge status-${r.status}`}>{r.status}</span></td>
                            <td>{new Date(r.created_at).toLocaleDateString()}</td>
                            <td>
                              <div style={{ display: 'flex', gap: '8px' }}>
                                <button
                                  onClick={async () => {
                                    if (confirm('Are you sure you want to ban this user?')) {
                                      await fetch('http://localhost:8080/api/admin/ban', {
                                        method: 'POST',
                                        headers: { 'Content-Type': 'application/json' },
                                        body: JSON.stringify({ user_id: r.reporter, reason: r.reason })
                                      });
                                      alert('User banned successfully');
                                    }
                                  }}
                                  style={{ background: 'rgba(255,0,76,0.1)', cursor: 'pointer', border: '1px solid #ff004c', color: '#ff004c', padding: '4px 8px', borderRadius: '4px', fontSize: '11px', fontWeight: 'bold' }}>
                                  BAN
                                </button>
                                <MoreVertical size={16} color="var(--text-muted)" style={{ cursor: 'pointer' }} />
                              </div>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  ) : (
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '300px', color: 'var(--text-muted)' }}>
                      <AlertOctagon size={48} style={{ marginBottom: '15px', color: 'var(--border-color)' }} />
                      <p>No pending reports. Great job!</p>
                    </div>
                  )}
                </div>
              </div>

              <div className="glass shadow-2xl" style={{ padding: '30px', borderRadius: '24px' }}>
                <h3 style={{ fontSize: '1.2rem', fontWeight: 800, marginBottom: '25px' }}>Live Transactions</h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                  {transactions.length > 0 ? (
                    transactions.map((tx, i) => (
                      <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '15px' }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: 'rgba(255,170,0,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <Gift size={20} color="#ffaa00" />
                        </div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>{tx.from_user} gifted {tx.to_user}</div>
                          <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>{new Date(tx.created_at).toLocaleTimeString()}</div>
                        </div>
                        <div style={{ fontWeight: 900, color: '#00ff8b' }}>+{tx.amount}</div>
                      </div>
                    ))
                  ) : (
                    // Mock transactions
                    [1, 2, 3, 4, 5].map((_, i) => (
                      <div key={i} style={{ display: 'flex', alignItems: 'center', gap: '15px', opacity: 1 - i * 0.15 }}>
                        <div style={{ width: '40px', height: '40px', borderRadius: '10px', background: 'rgba(255,170,0,0.1)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                          <Gift size={20} color="#ffaa00" />
                        </div>
                        <div style={{ flex: 1 }}>
                          <div style={{ fontWeight: 700, fontSize: '0.95rem' }}>User_{i} gifted Creator_{i + 5}</div>
                          <div style={{ fontSize: '0.8rem', color: 'var(--text-muted)' }}>2m ago</div>
                        </div>
                        <div style={{ fontWeight: 900, color: '#00ff8b' }}>+100</div>
                      </div>
                    ))
                  )}
                </div>
              </div>
            </div>
          </motion.div>
        )}
      </main>
    </div>
  )
}

const SidebarItem = ({ icon, label, active, onClick }: { icon: any, label: string, active: boolean, onClick: () => void }) => (
  <div
    onClick={onClick}
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: '12px',
      padding: '12px 20px',
      borderRadius: '12px',
      cursor: 'pointer',
      background: active ? 'linear-gradient(90deg, rgba(255,0,229,0.15) 0%, transparent 100%)' : 'transparent',
      color: active ? 'var(--brand-primary)' : 'var(--text-muted)',
      borderLeft: `4px solid ${active ? 'var(--brand-primary)' : 'transparent'}`,
      transition: 'all 0.2s',
      fontWeight: active ? 700 : 500
    }}
    onMouseEnter={(e) => {
      if (!active) e.currentTarget.style.color = 'white'
    }}
    onMouseLeave={(e) => {
      if (!active) e.currentTarget.style.color = 'var(--text-muted)'
    }}
  >
    {icon}
    <span style={{ fontSize: '1rem' }}>{label}</span>
  </div>
)

const StatCard = ({ title, value, icon, growth }: { title: string, value: string, icon: any, growth: string }) => (
  <div className="glass stat-card">
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: '20px' }}>
      <div style={{ width: '48px', height: '48px', borderRadius: '14px', background: 'rgba(255,255,255,0.03)', border: '1px solid var(--border-color)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        {icon}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: '4px', color: '#00ff8b', fontSize: '0.85rem', fontWeight: 700, background: 'rgba(0,255,139,0.08)', padding: '4px 8px', borderRadius: '8px' }}>
        <TrendingUp size={14} />
        {growth}
      </div>
    </div>
    <div style={{ fontSize: '0.9rem', color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '1px', marginBottom: '8px' }}>{title}</div>
    <div style={{ fontSize: '2.4rem', fontWeight: 900, letterSpacing: '-1px' }}>{value}</div>
  </div>
)

export default App
