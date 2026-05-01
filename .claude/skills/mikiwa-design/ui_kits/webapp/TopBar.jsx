/* global React */
const { Icon, Button } = window.UI;

function TopBar({ role, setRole, theme, setTheme, title }) {
  return (
    <header style={{
      height: 64, flexShrink: 0,
      borderBottom: '1px solid var(--border-subtle)',
      background: 'var(--surface)',
      display: 'flex', alignItems: 'center', gap: 16,
      padding: '0 24px',
      position: 'sticky', top: 0, zIndex: 10,
    }}>
      <h1 style={{ margin: 0, fontFamily: 'var(--font-display)', fontWeight: 700, fontSize: 20, color: 'var(--fg-1)' }}>{title}</h1>
      <div style={{ flex: 1 }}/>
      <div style={{ position: 'relative', width: 280 }}>
        <Icon name="search" size={16} style={{ position: 'absolute', left: 12, top: '50%', transform: 'translateY(-50%)', color: 'var(--fg-4)' }}/>
        <input placeholder="Suchen…" style={{
          width: '100%', padding: '8px 12px 8px 36px',
          fontFamily: 'var(--font-body)', fontSize: 14,
          borderRadius: 'var(--radius-pill)',
          border: '1px solid var(--border-default)',
          background: 'var(--surface-sunken)', color: 'var(--fg-1)',
          outline: 'none', boxSizing: 'border-box',
        }}/>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4, padding: 3, background: 'var(--surface-sunken)', borderRadius: 999, border: '1px solid var(--border-subtle)' }}>
        {['staff', 'parent'].map(r => (
          <button key={r} onClick={() => setRole(r)} style={{
            padding: '5px 12px', fontSize: 12, fontWeight: 700,
            borderRadius: 999, border: 'none', cursor: 'pointer',
            background: role === r ? 'var(--surface)' : 'transparent',
            color: role === r ? 'var(--fg-1)' : 'var(--fg-3)',
            boxShadow: role === r ? 'var(--shadow-xs)' : 'none',
            fontFamily: 'var(--font-body)',
          }}>{r === 'staff' ? 'Betreuer:in' : 'Eltern'}</button>
        ))}
      </div>
      <button onClick={() => setTheme(theme === 'light' ? 'dark' : 'light')} style={{
        width: 36, height: 36, borderRadius: 999,
        border: '1px solid var(--border-default)',
        background: 'var(--surface)', cursor: 'pointer',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        color: 'var(--fg-2)',
      }} title="Theme wechseln">
        <Icon name={theme === 'light' ? 'moon' : 'sun'} size={16}/>
      </button>
      <button style={{
        width: 36, height: 36, borderRadius: 999,
        border: '1px solid var(--border-default)',
        background: 'var(--surface)', cursor: 'pointer', position: 'relative',
        display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
        color: 'var(--fg-2)',
      }}>
        <Icon name="bell" size={16}/>
        <span style={{ position: 'absolute', top: 6, right: 8, width: 8, height: 8, borderRadius: 999, background: 'var(--coral-500)', border: '2px solid var(--surface)' }}/>
      </button>
    </header>
  );
}

window.TopBar = TopBar;
