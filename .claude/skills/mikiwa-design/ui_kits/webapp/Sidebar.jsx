/* global React */
const { useState } = React;
const { Icon, Avatar } = window.UI;

const STAFF_NAV = [
  { id: 'dashboard', label: 'Übersicht', icon: 'home' },
  { id: 'attendance', label: 'Anwesenheit', icon: 'check-circle-2' },
  { id: 'calendar', label: 'Kalender', icon: 'calendar' },
  { id: 'children', label: 'Kinder', icon: 'users' },
  { id: 'parents', label: 'Eltern', icon: 'user-round' },
  { id: 'messages', label: 'Mitteilungen', icon: 'message-circle', badge: 3 },
  { id: 'settings', label: 'Einstellungen', icon: 'settings' },
];
const PARENT_NAV = [
  { id: 'parent-home', label: 'Start', icon: 'home' },
  { id: 'parent-calendar', label: 'Kalender', icon: 'calendar' },
  { id: 'parent-messages', label: 'Mitteilungen', icon: 'message-circle', badge: 1 },
  { id: 'parent-child', label: 'Mein Kind', icon: 'heart' },
];

function Sidebar({ role, route, setRoute }) {
  const items = role === 'staff' ? STAFF_NAV : PARENT_NAV;
  return (
    <aside style={{
      width: 264, flexShrink: 0,
      borderRight: '1px solid var(--border-subtle)',
      background: 'var(--surface)',
      display: 'flex', flexDirection: 'column',
      height: '100vh', position: 'sticky', top: 0,
    }}>
      <div style={{ padding: '20px 20px 14px', display: 'flex', alignItems: 'center', gap: 10 }}>
        <img src="../../assets/logo-mikiwa.svg" width="32" height="32" alt=""/>
        <div style={{ display: 'flex', flexDirection: 'column', lineHeight: 1.1 }}>
          <span style={{ fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 18, color: 'var(--fg-1)', letterSpacing: '-0.02em' }}>mikiwa</span>
          <span style={{ fontSize: 11, color: 'var(--fg-4)', fontWeight: 600 }}>{role === 'staff' ? 'Verwaltung' : 'Familienbereich'}</span>
        </div>
      </div>
      <nav style={{ padding: '8px 12px', display: 'flex', flexDirection: 'column', gap: 2, flex: 1 }}>
        {items.map(item => {
          const active = route === item.id;
          return (
            <button key={item.id} onClick={() => setRoute(item.id)} style={{
              display: 'flex', alignItems: 'center', gap: 12,
              padding: '10px 12px',
              borderRadius: 'var(--radius-md)',
              background: active ? 'var(--accent-soft)' : 'transparent',
              color: active ? 'var(--sun-800)' : 'var(--fg-2)',
              border: 'none', cursor: 'pointer',
              fontFamily: 'var(--font-body)', fontWeight: active ? 700 : 500, fontSize: 14,
              textAlign: 'left', position: 'relative',
              transition: 'all 120ms var(--ease-soft)',
            }}
            onMouseEnter={e => { if (!active) e.currentTarget.style.background = 'var(--surface-hover)'; }}
            onMouseLeave={e => { if (!active) e.currentTarget.style.background = 'transparent'; }}
            >
              <Icon name={item.icon} size={18} />
              <span style={{ flex: 1 }}>{item.label}</span>
              {item.badge && (
                <span style={{ minWidth: 20, height: 20, padding: '0 6px', borderRadius: 999, background: 'var(--coral-500)', color: '#fff', fontSize: 11, fontWeight: 700, display: 'inline-flex', alignItems: 'center', justifyContent: 'center' }}>{item.badge}</span>
              )}
            </button>
          );
        })}
      </nav>
      <div style={{ padding: 16, borderTop: '1px solid var(--border-subtle)', display: 'flex', alignItems: 'center', gap: 10 }}>
        <Avatar name={role === 'staff' ? 'Sabine Berger' : 'Familie Huber'} size={36}/>
        <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0, flex: 1 }}>
          <span style={{ fontSize: 13, fontWeight: 700, color: 'var(--fg-1)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{role === 'staff' ? 'Sabine Berger' : 'Familie Huber'}</span>
          <span style={{ fontSize: 11, color: 'var(--fg-4)' }}>{role === 'staff' ? 'Pädagogin' : 'Eltern'}</span>
        </div>
        <Icon name="chevron-right" size={16} style={{ color: 'var(--fg-4)' }}/>
      </div>
    </aside>
  );
}

window.Sidebar = Sidebar;
