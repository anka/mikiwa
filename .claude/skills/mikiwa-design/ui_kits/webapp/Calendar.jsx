/* global React */
const { Card, Badge } = window.UI;

const EVENTS = {
  6: [{ title: 'Waldtag', tone: 'success' }],
  12: [{ title: 'Elternabend', tone: 'info' }],
  18: [{ title: 'Geburtstag Lena', tone: 'accent' }],
  20: [{ title: 'Anmeldeschluss', tone: 'warning' }],
  27: [{ title: 'Sommerfest', tone: 'accent' }],
};

function Calendar() {
  // May 2026: starts on Friday (5), 31 days
  const startDow = 4; // Mon=0... Friday=4
  const daysInMonth = 31;
  const cells = [];
  for (let i = 0; i < startDow; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(d);
  while (cells.length % 7) cells.push(null);

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <h2 style={{ margin: 0, fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 28, letterSpacing: '-0.02em', color: 'var(--fg-1)' }}>Kalender</h2>
          <p style={{ margin: '4px 0 0', color: 'var(--fg-3)', fontSize: 14 }}>Mai 2026</p>
        </div>
        <div style={{ display: 'flex', gap: 4, padding: 4, background: 'var(--surface-sunken)', borderRadius: 999 }}>
          {['Monat', 'Woche', 'Tag'].map((v, i) => (
            <button key={v} style={{
              padding: '6px 14px', fontSize: 13, fontWeight: 600,
              borderRadius: 999, border: 'none', cursor: 'pointer',
              background: i === 0 ? 'var(--surface)' : 'transparent',
              color: i === 0 ? 'var(--fg-1)' : 'var(--fg-3)',
              boxShadow: i === 0 ? 'var(--shadow-xs)' : 'none',
              fontFamily: 'var(--font-body)',
            }}>{v}</button>
          ))}
        </div>
      </div>
      <Card padding={0}>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', borderBottom: '1px solid var(--border-subtle)' }}>
          {['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'].map(d => (
            <div key={d} style={{ padding: '12px 14px', fontSize: 11, fontWeight: 700, color: 'var(--fg-3)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>{d}</div>
          ))}
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)' }}>
          {cells.map((d, i) => {
            const today = d === 4;
            const events = (d && EVENTS[d]) || [];
            return (
              <div key={i} style={{
                minHeight: 96, padding: 8,
                borderRight: (i + 1) % 7 ? '1px solid var(--border-subtle)' : 'none',
                borderTop: i >= 7 ? '1px solid var(--border-subtle)' : 'none',
                background: today ? 'var(--accent-soft)' : 'var(--surface)',
                opacity: d ? 1 : 0.4,
              }}>
                <div style={{
                  display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                  width: 24, height: 24, borderRadius: 999,
                  background: today ? 'var(--accent)' : 'transparent',
                  color: today ? 'var(--accent-on)' : 'var(--fg-2)',
                  fontWeight: today ? 800 : 600, fontSize: 12,
                }}>{d || ''}</div>
                <div style={{ marginTop: 6, display: 'flex', flexDirection: 'column', gap: 4 }}>
                  {events.map((e, j) => (
                    <div key={j} style={{
                      fontSize: 11, fontWeight: 600,
                      padding: '3px 6px', borderRadius: 6,
                      background: `var(--${e.tone}-soft, var(--surface-sunken))`,
                      color: e.tone === 'accent' ? 'var(--sun-800)' : `var(--${e.tone})`,
                      overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                    }}>{e.title}</div>
                  ))}
                </div>
              </div>
            );
          })}
        </div>
      </Card>
    </div>
  );
}

window.Calendar = Calendar;
