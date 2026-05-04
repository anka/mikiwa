/* global React, PageHeader, FormSection, FormGrid, FormField */
const { useState } = React;
const { Card, Button, Badge, Icon } = window.UI;

function FormShowcase({ navigate }) {
  const [text, setText] = useState('Lena Huber');
  const [textarea, setTextarea] = useState('Erdnussallergie. Lieblingsspiel: Sandkasten.');
  const [select, setSelect] = useState('Sonnenblume');
  const [date, setDate] = useState('2021-09-14');
  const [time, setTime] = useState('08:30');
  const [number, setNumber] = useState(14);
  const [range, setRange] = useState(60);
  const [checks, setChecks] = useState({ news: true, photos: false, terms: false });
  const [radio, setRadio] = useState('halftime');
  const [groups, setGroups] = useState(['Sonnenblume', 'Marienkäfer']);
  const [toggle, setToggle] = useState(true);

  const allGroups = ['Sonnenblume', 'Marienkäfer', 'Schmetterlinge'];

  return (
    <div>
      <PageHeader
        title="Formularfelder"
        subtitle="Alle verfügbaren Eingabe­elemente — Referenz für Konsistenz."
        secondary={[{ label: 'Abbrechen' }]}
        primary={{ label: 'Speichern', icon: 'check' }}
      />
      <Card style={{ maxWidth: 880 }}>
        <FormSection title="Text" desc="Einzeilig, mehrzeilig, mit Hilfetext und Fehler­zustand.">
          <FormGrid cols={2}>
            <FormField label="Vorname *">
              <input className="mw-input" value={text} onChange={e => setText(e.target.value)}/>
            </FormField>
            <FormField label="E-Mail *" hint="Wird nur für Krankmeldungen verwendet.">
              <input className="mw-input" type="email" placeholder="name@example.at"/>
            </FormField>
            <FormField label="Telefon" error="Bitte gültige Nummer eingeben.">
              <input className="mw-input mw-input-error" defaultValue="0664-12"/>
            </FormField>
            <FormField label="Mit Icon">
              <div className="mw-input-wrap">
                <Icon name="search" size={16} style={{ color: 'var(--fg-4)' }}/>
                <input className="mw-input mw-input-iconed" placeholder="Suchen…"/>
              </div>
            </FormField>
            <FormField label="Notizen" full>
              <textarea className="mw-input" rows="4" value={textarea} onChange={e => setTextarea(e.target.value)}/>
            </FormField>
            <FormField label="Schreib­geschützt">
              <input className="mw-input" readOnly value="K-2026-0114"/>
            </FormField>
            <FormField label="Deaktiviert">
              <input className="mw-input" disabled value="—"/>
            </FormField>
          </FormGrid>
        </FormSection>

        <FormSection title="Auswahl" desc="Dropdown, native und benutzerdefiniertes Multi-Select.">
          <FormGrid cols={2}>
            <FormField label="Gruppe">
              <div className="mw-select-wrap">
                <select className="mw-select" value={select} onChange={e => setSelect(e.target.value)}>
                  <option>Sonnenblume</option>
                  <option>Marienkäfer</option>
                  <option>Schmetterlinge</option>
                </select>
              </div>
            </FormField>
            <FormField label="Mehrere Gruppen" hint="Tippen zum Hinzufügen oder Entfernen.">
              <div className="mw-multi">
                {groups.map(g => (
                  <span key={g} className="mw-chip">
                    {g}
                    <button onClick={() => setGroups(gs => gs.filter(x => x !== g))} className="mw-chip-x"><Icon name="x" size={10}/></button>
                  </span>
                ))}
                {allGroups.filter(g => !groups.includes(g)).map(g => (
                  <button key={g} className="mw-chip mw-chip-add" onClick={() => setGroups(gs => [...gs, g])}>
                    <Icon name="plus" size={10}/>{g}
                  </button>
                ))}
              </div>
            </FormField>
          </FormGrid>
        </FormSection>

        <FormSection title="Datum & Zahl" desc="Native Pickers für maximale Kompatibilität.">
          <FormGrid cols={3}>
            <FormField label="Datum">
              <input className="mw-input" type="date" value={date} onChange={e => setDate(e.target.value)}/>
            </FormField>
            <FormField label="Uhrzeit">
              <input className="mw-input" type="time" value={time} onChange={e => setTime(e.target.value)}/>
            </FormField>
            <FormField label="Anzahl Kinder">
              <input className="mw-input" type="number" value={number} onChange={e => setNumber(+e.target.value)} min="0" max="30"/>
            </FormField>
            <FormField label={`Auslastung: ${range}%`} full>
              <input type="range" min="0" max="100" value={range} onChange={e => setRange(+e.target.value)} className="mw-range"/>
            </FormField>
          </FormGrid>
        </FormSection>

        <FormSection title="Optionen" desc="Checkbox, Radio, Toggle.">
          <FormGrid cols={1}>
            <FormField label="Checkboxen">
              <div className="mw-stack">
                <label className="mw-check"><input type="checkbox" checked={checks.news} onChange={e => setChecks({ ...checks, news: e.target.checked })}/> Newsletter abonnieren</label>
                <label className="mw-check"><input type="checkbox" checked={checks.photos} onChange={e => setChecks({ ...checks, photos: e.target.checked })}/> Fotos im Eltern­bereich erlauben</label>
                <label className="mw-check"><input type="checkbox" checked={checks.terms} onChange={e => setChecks({ ...checks, terms: e.target.checked })}/> Allgemeine Geschäfts­bedingungen</label>
              </div>
            </FormField>
            <FormField label="Betreuungs­zeit">
              <div className="mw-stack">
                {[['halftime','Halbtags · 07:30–13:00'],['fulltime','Ganztags · 07:30–17:00'],['flex','Flexibel']].map(([v,l]) => (
                  <label key={v} className="mw-radio"><input type="radio" name="bt" checked={radio===v} onChange={() => setRadio(v)}/> {l}</label>
                ))}
              </div>
            </FormField>
            <FormField label="Push-Benachrichtigungen">
              <div className="mw-toggle-row">
                <span className="mw-toggle-text">
                  <span className="mw-toggle-text-label">Push-Benachrichtigungen</span>
                  <span className="mw-toggle-text-state">{toggle ? 'Aktiv — Sie erhalten Hinweise auf neue Mitteilungen.' : 'Aus — keine Hinweise.'}</span>
                </span>
                <label className="mw-toggle">
                  <input type="checkbox" checked={toggle} onChange={e => setToggle(e.target.checked)}/>
                  <span className="mw-toggle-track"><span className="mw-toggle-thumb"/></span>
                </label>
              </div>
            </FormField>
            <FormField label="Datei-Upload">
              <label className="mw-upload">
                <Icon name="upload" size={16} style={{ color: 'var(--fg-3)' }}/>
                <span style={{ fontSize: 13, color: 'var(--fg-2)', fontWeight: 600 }}>Datei wählen oder hierher ziehen</span>
                <input type="file" style={{ display: 'none' }}/>
              </label>
            </FormField>
          </FormGrid>
        </FormSection>

        <FormSection title="Farb-Auswahl">
          <FormGrid cols={2}>
            <FormField label="Gruppen­farbe">
              <div className="mw-color-row">
                {['var(--sun-500)','var(--leaf-500)','var(--sky-500)','var(--coral-500)','var(--berry-500)'].map((c, i) => (
                  <button key={i} className="mw-color-dot" style={{ background: c, outline: i === 0 ? '2px solid var(--fg-1)' : 'none', outlineOffset: 2 }}/>
                ))}
              </div>
            </FormField>
            <FormField label="Suche mit Treffern">
              <div className="mw-input-wrap">
                <Icon name="search" size={16} style={{ color: 'var(--fg-4)' }}/>
                <input className="mw-input mw-input-iconed" defaultValue="Lena"/>
                <Badge tone="neutral" style={{ position: 'absolute', right: 8, top: '50%', transform: 'translateY(-50%)' }}>3 Treffer</Badge>
              </div>
            </FormField>
          </FormGrid>
        </FormSection>
      </Card>
    </div>
  );
}

window.FormShowcase = FormShowcase;
