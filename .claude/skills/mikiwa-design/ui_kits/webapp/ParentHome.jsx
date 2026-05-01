/* global React */
const { Card, Badge, Button, Avatar, Icon } = window.UI;

function ParentHome() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 24, maxWidth: 880 }}>
      <div>
        <h2 style={{ margin: 0, fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 32, letterSpacing: '-0.02em', color: 'var(--fg-1)' }}>Guten Morgen, Familie Huber</h2>
        <p style={{ margin: '6px 0 0', color: 'var(--fg-3)', fontSize: 15 }}>Hier ist alles Wichtige für Lena.</p>
      </div>

      <Card style={{ display: 'flex', gap: 18, alignItems: 'center' }}>
        <Avatar name="Lena Huber" size={64}/>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 18, fontWeight: 700, color: 'var(--fg-1)' }}>Lena ist heute eingetragen.</div>
          <div style={{ fontSize: 14, color: 'var(--fg-3)' }}>Gruppe Sonnenblume · seit 07:42 · Pädagogin Sabine</div>
        </div>
        <Badge tone="success" dot>anwesend</Badge>
      </Card>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <Card>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: 'var(--fg-1)' }}>Anstehend</h3>
            <a style={{ fontSize: 13, fontWeight: 600, color: 'var(--fg-link)', cursor: 'pointer' }}>Alle ansehen</a>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <Upcoming date="Mi 06.05." title="Waldtag" sub="Treffpunkt 08:30 · feste Schuhe mitgeben"/>
            <Upcoming date="Sa 27.06." title="Sommerfest" sub="Eltern + Kinder · 14:00–17:00" tone="accent"/>
          </div>
        </Card>

        <Card>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
            <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: 'var(--fg-1)' }}>Schnellaktionen</h3>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <Action icon="thermometer" label="Krankmeldung senden"/>
            <Action icon="clock" label="Verspätung melden"/>
            <Action icon="calendar-x" label="Urlaub eintragen"/>
            <Action icon="message-circle" label="Nachricht an Sabine"/>
          </div>
        </Card>
      </div>

      <Card>
        <h3 style={{ margin: '0 0 12px', fontSize: 16, fontWeight: 700, color: 'var(--fg-1)' }}>Letzte Mitteilung</h3>
        <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start', padding: 14, background: 'var(--accent-soft)', borderRadius: 'var(--radius-md)' }}>
          <Avatar name="Sabine Berger" size={40}/>
          <div style={{ flex: 1 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
              <span style={{ fontWeight: 700, color: 'var(--fg-1)', fontSize: 14 }}>Sabine · Pädagogin</span>
              <span style={{ fontSize: 12, color: 'var(--fg-4)' }}>Heute, 09:30</span>
            </div>
            <div style={{ fontSize: 14, color: 'var(--fg-1)', marginTop: 4, lineHeight: 1.5 }}>
              Heute haben wir im Garten gepflanzt — Lena war ganz begeistert von den Sonnenblumen. Bilder folgen heute Abend.
            </div>
          </div>
        </div>
      </Card>
    </div>
  );
}

function Upcoming({ date, title, sub, tone }) {
  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'flex-start' }}>
      <div style={{
        flexShrink: 0, padding: '6px 10px',
        borderRadius: 'var(--radius-md)',
        background: tone === 'accent' ? 'var(--accent-soft)' : 'var(--surface-sunken)',
        border: '1px solid var(--border-subtle)',
        fontSize: 12, fontWeight: 700,
        color: tone === 'accent' ? 'var(--sun-800)' : 'var(--fg-2)',
      }}>{date}</div>
      <div>
        <div style={{ fontSize: 14, fontWeight: 700, color: 'var(--fg-1)' }}>{title}</div>
        <div style={{ fontSize: 12, color: 'var(--fg-3)' }}>{sub}</div>
      </div>
    </div>
  );
}

function Action({ icon, label }) {
  return (
    <button style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '10px 12px',
      background: 'var(--surface)', border: '1px solid var(--border-subtle)',
      borderRadius: 'var(--radius-md)', cursor: 'pointer',
      color: 'var(--fg-1)', fontFamily: 'var(--font-body)',
      fontSize: 14, fontWeight: 600, textAlign: 'left',
    }}>
      <Icon name={icon} size={16} style={{ color: 'var(--accent)' }}/>
      <span style={{ flex: 1 }}>{label}</span>
      <Icon name="chevron-right" size={14} style={{ color: 'var(--fg-4)' }}/>
    </button>
  );
}

window.ParentHome = ParentHome;
