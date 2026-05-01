/* global React, KIDS, StatusBadge */
const { useState } = React;
const { Card, Button, Avatar, Icon, Badge } = window.UI;

function Attendance() {
  const [kids, setKids] = useState(window.KIDS);
  const setStatus = (id, status) => setKids(ks => ks.map(k => k.id === id ? { ...k, status, time: status === 'present' || status === 'late' ? '09:14' : null } : k));
  const counts = { present: 0, late: 0, sick: 0, absent: 0, pending: 0 };
  kids.forEach(k => counts[k.status]++);
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, justifyContent: 'space-between' }}>
        <div>
          <h2 style={{ margin: 0, fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 28, letterSpacing: '-0.02em', color: 'var(--fg-1)' }}>Anwesenheit</h2>
          <p style={{ margin: '4px 0 0', color: 'var(--fg-3)', fontSize: 14 }}>Montag, 4. Mai 2026 · Gruppe Sonnenblume</p>
        </div>
        <div style={{ display: 'flex', gap: 8 }}>
          <Button variant="secondary" icon="filter">Gruppe filtern</Button>
          <Button variant="primary" icon="download">Liste exportieren</Button>
        </div>
      </div>
      <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
        <Badge tone="success" dot>{counts.present} anwesend</Badge>
        <Badge tone="warning" dot>{counts.late} verspätet</Badge>
        <Badge tone="info" dot>{counts.sick} krank</Badge>
        <Badge tone="danger" dot>{counts.absent} abwesend</Badge>
        <Badge tone="neutral" dot>{counts.pending} offen</Badge>
      </div>
      <Card padding={0}>
        <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: 'var(--font-body)' }}>
          <thead>
            <tr style={{ background: 'var(--surface-sunken)' }}>
              <Th>Kind</Th><Th>Gruppe</Th><Th>Status</Th><Th>Uhrzeit</Th><Th>Eintragen</Th>
            </tr>
          </thead>
          <tbody>
            {kids.map(k => (
              <tr key={k.id} style={{ borderTop: '1px solid var(--border-subtle)' }}>
                <td style={{ padding: '12px 16px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <Avatar name={k.name} size={32}/>
                    <span style={{ fontWeight: 600, color: 'var(--fg-1)', fontSize: 14 }}>{k.name}</span>
                  </div>
                </td>
                <td style={{ padding: '12px 16px', color: 'var(--fg-2)', fontSize: 14 }}>{k.group}</td>
                <td style={{ padding: '12px 16px' }}><StatusBadge status={k.status}/></td>
                <td style={{ padding: '12px 16px', color: 'var(--fg-3)', fontSize: 13, fontFamily: 'var(--font-mono)' }}>{k.time || '—'}</td>
                <td style={{ padding: '8px 16px' }}>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <ActionDot active={k.status === 'present'} color="var(--success)" onClick={() => setStatus(k.id, 'present')} title="anwesend"/>
                    <ActionDot active={k.status === 'late'} color="var(--warning)" onClick={() => setStatus(k.id, 'late')} title="verspätet"/>
                    <ActionDot active={k.status === 'sick'} color="var(--info)" onClick={() => setStatus(k.id, 'sick')} title="krank"/>
                    <ActionDot active={k.status === 'absent'} color="var(--danger)" onClick={() => setStatus(k.id, 'absent')} title="abwesend"/>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

function Th({ children }) {
  return <th style={{ padding: '10px 16px', textAlign: 'left', fontSize: 11, fontWeight: 700, color: 'var(--fg-3)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>{children}</th>;
}

function ActionDot({ active, color, onClick, title }) {
  return (
    <button onClick={onClick} title={title} style={{
      width: 24, height: 24, borderRadius: 999,
      border: active ? `2px solid ${color}` : '1px solid var(--border-default)',
      background: active ? color : 'var(--surface)',
      cursor: 'pointer', padding: 0,
      transition: 'all 120ms var(--ease-soft)',
    }}/>
  );
}

window.Attendance = Attendance;
