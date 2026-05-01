/* global React */
const { useState } = React;
const { Card, Badge, Button, Avatar, Icon } = window.UI;

const KIDS = [
  { id: 1, name: 'Lena Huber', group: 'Sonnenblume', status: 'present', time: '07:42' },
  { id: 2, name: 'Maximilian Steiner', group: 'Sonnenblume', status: 'present', time: '08:01' },
  { id: 3, name: 'Tobias Klammer', group: 'Marienkäfer', status: 'late', time: '09:14' },
  { id: 4, name: 'Emma Wieser', group: 'Sonnenblume', status: 'sick', time: null },
  { id: 5, name: 'Jonas Berger', group: 'Marienkäfer', status: 'absent', time: null },
  { id: 6, name: 'Sophia Pirker', group: 'Sonnenblume', status: 'pending', time: null },
];

function Dashboard() {
  const present = KIDS.filter(k => k.status === 'present').length;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
      <div>
        <h2 style={{ margin: 0, fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 32, letterSpacing: '-0.02em', color: 'var(--fg-1)' }}>Guten Morgen, Sabine</h2>
        <p style={{ margin: '6px 0 0', color: 'var(--fg-3)', fontSize: 15 }}>Montag, 4. Mai 2026 · 09:12</p>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 16 }}>
        <KPI label="Heute anwesend" value={present} of={KIDS.length} icon="check-circle-2" tone="success"/>
        <KPI label="Verspätet" value="1" icon="clock" tone="warning"/>
        <KPI label="Krankgemeldet" value="1" icon="thermometer" tone="info"/>
        <KPI label="Nachrichten" value="3" icon="message-circle" tone="accent"/>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 16 }}>
        <Card>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: 'var(--fg-1)' }}>Heutige Anwesenheit</h3>
            <Badge tone="success" dot>Live</Badge>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {KIDS.slice(0, 5).map(k => (
              <div key={k.id} style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '8px 0', borderBottom: '1px solid var(--border-subtle)' }}>
                <Avatar name={k.name} size={32}/>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 600, color: 'var(--fg-1)' }}>{k.name}</div>
                  <div style={{ fontSize: 12, color: 'var(--fg-4)' }}>{k.group} {k.time && `· ${k.time}`}</div>
                </div>
                <StatusBadge status={k.status}/>
              </div>
            ))}
          </div>
        </Card>
        <Card>
          <h3 style={{ margin: '0 0 14px', fontSize: 16, fontWeight: 700, color: 'var(--fg-1)' }}>Anstehend</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            <Event date="Mi, 06.05." title="Waldtag" sub="Treffpunkt 08:30 · Stadtpark"/>
            <Event date="Sa, 27.06." title="Sommerfest" sub="Eltern + Kinder · 14:00–17:00" tone="accent"/>
            <Event date="Mo, 13.07." title="Elterngespräche" sub="Sonnenblume · ganztägig"/>
          </div>
        </Card>
      </div>
    </div>
  );
}

function KPI({ label, value, of, icon, tone }) {
  const tones = {
    success: 'var(--success)',
    warning: 'var(--warning)',
    info: 'var(--info)',
    accent: 'var(--accent)',
  };
  return (
    <Card>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
        <span style={{ fontSize: 12, fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase', color: 'var(--fg-3)' }}>{label}</span>
        <span style={{ width: 32, height: 32, borderRadius: 999, background: `color-mix(in oklch, ${tones[tone]} 15%, transparent)`, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', color: tones[tone] }}>
          <Icon name={icon} size={16}/>
        </span>
      </div>
      <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
        <span style={{ fontFamily: 'var(--font-display)', fontSize: 36, fontWeight: 800, color: 'var(--fg-1)', letterSpacing: '-0.02em' }}>{value}</span>
        {of && <span style={{ color: 'var(--fg-3)', fontSize: 14, fontWeight: 600 }}>/ {of}</span>}
      </div>
    </Card>
  );
}

function StatusBadge({ status }) {
  const map = {
    present: { tone: 'success', label: 'anwesend' },
    late: { tone: 'warning', label: 'verspätet' },
    sick: { tone: 'info', label: 'krank' },
    absent: { tone: 'danger', label: 'abwesend' },
    pending: { tone: 'neutral', label: 'offen' },
  };
  const m = map[status];
  return <Badge tone={m.tone} dot>{m.label}</Badge>;
}

function Event({ date, title, sub, tone }) {
  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
      <div style={{
        flexShrink: 0, width: 56,
        padding: '6px 0', borderRadius: 'var(--radius-md)',
        background: tone === 'accent' ? 'var(--accent-soft)' : 'var(--surface-sunken)',
        textAlign: 'center',
        border: '1px solid var(--border-subtle)',
      }}>
        <div style={{ fontSize: 10, fontWeight: 700, color: tone === 'accent' ? 'var(--sun-800)' : 'var(--fg-3)', textTransform: 'uppercase', letterSpacing: '0.05em' }}>{date.split(',')[0]}</div>
        <div style={{ fontSize: 14, fontWeight: 800, color: 'var(--fg-1)' }}>{date.split(',')[1]?.trim() || date}</div>
      </div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--fg-1)' }}>{title}</div>
        <div style={{ fontSize: 12, color: 'var(--fg-3)' }}>{sub}</div>
      </div>
    </div>
  );
}

window.Dashboard = Dashboard;
window.KIDS = KIDS;
window.StatusBadge = StatusBadge;
