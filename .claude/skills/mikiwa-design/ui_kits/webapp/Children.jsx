/* global React, PageHeader */
const { useState } = React;
const { Card, Button, Avatar, Icon, Badge } = window.UI;

const KIDS_LIST = [
  { id: 1, name: 'Lena Huber', group: 'Sonnenblume', born: '14.09.2021', parents: 'Familie Huber' },
  { id: 2, name: 'Maximilian Steiner', group: 'Sonnenblume', born: '02.03.2021', parents: 'Familie Steiner' },
  { id: 3, name: 'Tobias Klammer', group: 'Marienkäfer', born: '21.11.2022', parents: 'Familie Klammer' },
  { id: 4, name: 'Emma Wieser', group: 'Sonnenblume', born: '08.06.2021', parents: 'Familie Wieser' },
  { id: 5, name: 'Jonas Berger', group: 'Marienkäfer', born: '17.01.2022', parents: 'Familie Berger' },
  { id: 6, name: 'Sophia Pirker', group: 'Sonnenblume', born: '30.04.2021', parents: 'Familie Pirker' },
];

function Children({ navigate }) {
  return (
    <div>
      <PageHeader
        title="Kinder"
        subtitle={`${KIDS_LIST.length} Kinder in 2 Gruppen`}
        primary={{ label: 'Kind hinzufügen', icon: 'plus', onClick: () => navigate('children-new') }}
      />
      <Card padding={0}>
        <table style={{ width: '100%', borderCollapse: 'collapse', fontFamily: 'var(--font-body)' }}>
          <thead>
            <tr style={{ background: 'var(--surface-sunken)' }}>
              <Th>Kind</Th><Th>Gruppe</Th><Th>Geboren</Th><Th>Eltern</Th><Th></Th>
            </tr>
          </thead>
          <tbody>
            {KIDS_LIST.map(k => (
              <tr key={k.id} style={{ borderTop: '1px solid var(--border-subtle)', cursor: 'pointer' }}
                  onClick={() => navigate('children-detail', k.id)}
                  onMouseEnter={e => e.currentTarget.style.background = 'var(--surface-hover)'}
                  onMouseLeave={e => e.currentTarget.style.background = 'transparent'}>
                <td style={{ padding: '12px 16px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <Avatar name={k.name} size={32}/>
                    <span style={{ fontWeight: 600, color: 'var(--fg-1)', fontSize: 14 }}>{k.name}</span>
                  </div>
                </td>
                <td style={{ padding: '12px 16px' }}><Badge tone="accent">{k.group}</Badge></td>
                <td style={{ padding: '12px 16px', color: 'var(--fg-2)', fontSize: 14, fontFamily: 'var(--font-mono)' }}>{k.born}</td>
                <td style={{ padding: '12px 16px', color: 'var(--fg-2)', fontSize: 14 }}>{k.parents}</td>
                <td style={{ padding: '12px 16px', textAlign: 'right' }}><Icon name="chevron-right" size={16} style={{ color: 'var(--fg-4)' }}/></td>
              </tr>
            ))}
          </tbody>
        </table>
      </Card>
    </div>
  );
}

function ChildDetail({ navigate, childId }) {
  const k = KIDS_LIST.find(x => x.id === childId) || KIDS_LIST[0];
  return (
    <div>
      <PageHeader
        title={k.name}
        secondary={[
          { icon: 'x', label: 'Abmelden', tone: 'danger' },
          { icon: 'share-2', label: 'Teilen' },
        ]}
        primary={{ label: 'Bearbeiten', icon: 'pencil', onClick: () => navigate('children-edit', k.id) }}
        back={{ onClick: () => navigate('children') }}
      />
      <Card style={{ maxWidth: 720 }}>
        <DetailRow icon="calendar" label="Geburtsdatum" value={k.born}/>
        <DetailRow icon="users" label="Gruppe" value={k.group}/>
        <DetailRow icon="user-round" label="Eltern" value={k.parents}/>
        <DetailRow icon="phone" label="Telefon" value="+43 664 123 45 67"/>
        <DetailRow icon="mail" label="E-Mail" value="huber@example.at"/>
        <DetailRow icon="map-pin" label="Adresse" value="Gurktalerstrasse 16, 9560 Feldkirchen"/>
        <DetailRow icon="info" label="Notizen" value="Erdnussallergie. Lieblingsspiel: Sandkasten." last/>
      </Card>
    </div>
  );
}

function DetailRow({ icon, label, value, last }) {
  return (
    <div style={{
      display: 'grid', gridTemplateColumns: '24px 140px 1fr', gap: 12, alignItems: 'center',
      padding: '14px 4px',
      borderBottom: last ? 'none' : '1px solid var(--border-subtle)',
    }}>
      <Icon name={icon} size={16} style={{ color: 'var(--fg-4)' }}/>
      <span style={{ fontSize: 13, color: 'var(--fg-3)', fontWeight: 500 }}>{label}</span>
      <span style={{ fontSize: 14, color: 'var(--fg-1)', fontWeight: 500 }}>{value}</span>
    </div>
  );
}

function ChildForm({ navigate, mode = 'new', childId }) {
  const editing = mode === 'edit';
  const k = editing ? (KIDS_LIST.find(x => x.id === childId) || KIDS_LIST[0]) : null;
  const [name, setName] = useState(k?.name || '');
  const [group, setGroup] = useState(k?.group || 'Sonnenblume');
  const [born, setBorn] = useState(k?.born ? '2021-09-14' : '');

  return (
    <div>
      <PageHeader
        title={editing ? `${k.name} bearbeiten` : 'Neues Kind'}
        subtitle={editing ? null : 'Stammdaten des Kindes erfassen'}
        secondary={[
          { label: 'Abbrechen', onClick: () => navigate(editing ? 'children-detail' : 'children', childId) },
        ]}
        primary={{ label: 'Speichern', icon: 'check', onClick: () => navigate(editing ? 'children-detail' : 'children', childId) }}
      />
      <Card style={{ maxWidth: 720 }}>
        <FormSection title="Stammdaten" desc="Vor- und Nachname, Gruppe, Geburtsdatum.">
          <FormGrid cols={2}>
            <FormField label="Vorname *" required>
              <input className="mw-input" value={name.split(' ')[0] || ''} onChange={e => setName(e.target.value + ' ' + (name.split(' ')[1]||''))}/>
            </FormField>
            <FormField label="Nachname *" required>
              <input className="mw-input" value={name.split(' ')[1] || ''} onChange={e => setName((name.split(' ')[0]||'') + ' ' + e.target.value)}/>
            </FormField>
            <FormField label="Geburtsdatum *">
              <input type="date" className="mw-input" value={born} onChange={e => setBorn(e.target.value)}/>
            </FormField>
            <FormField label="Gruppe">
              <select className="mw-input" value={group} onChange={e => setGroup(e.target.value)}>
                <option>Sonnenblume</option>
                <option>Marienkäfer</option>
                <option>Schmetterlinge</option>
              </select>
            </FormField>
          </FormGrid>
        </FormSection>
        <FormSection title="Hinweise" desc="Allergien, Besonderheiten — nur für Pädagog:innen sichtbar.">
          <FormField label="Notizen">
            <textarea className="mw-input" rows="4" placeholder="z.B. Erdnussallergie, Schlafrhythmus, Lieblingsspiele …"/>
          </FormField>
        </FormSection>
      </Card>
    </div>
  );
}

function FormSection({ title, desc, children }) {
  return (
    <section style={{ marginBottom: 24, paddingBottom: 24, borderBottom: '1px solid var(--border-subtle)' }}>
      <div style={{ marginBottom: 14 }}>
        <h3 style={{ margin: 0, fontSize: 16, fontWeight: 700, color: 'var(--fg-1)' }}>{title}</h3>
        {desc && <p style={{ margin: '2px 0 0', fontSize: 13, color: 'var(--fg-3)' }}>{desc}</p>}
      </div>
      {children}
    </section>
  );
}

function FormGrid({ cols = 2, children }) {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: `repeat(${cols}, 1fr)`, gap: 14 }}>
      {children}
    </div>
  );
}

function FormField({ label, hint, error, required, children, full }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6, gridColumn: full ? '1 / -1' : 'auto' }}>
      <label style={{ fontSize: 13, fontWeight: 600, color: 'var(--fg-1)' }}>{label}</label>
      {children}
      {error && <span style={{ fontSize: 12, color: 'var(--danger)', fontWeight: 600 }}>{error}</span>}
      {hint && !error && <span style={{ fontSize: 12, color: 'var(--fg-4)' }}>{hint}</span>}
    </div>
  );
}

function Th({ children }) {
  return <th style={{ padding: '10px 16px', textAlign: 'left', fontSize: 11, fontWeight: 700, color: 'var(--fg-3)', textTransform: 'uppercase', letterSpacing: '0.06em' }}>{children}</th>;
}

window.Children = Children;
window.ChildDetail = ChildDetail;
window.ChildForm = ChildForm;
window.FormSection = FormSection;
window.FormGrid = FormGrid;
window.FormField = FormField;
