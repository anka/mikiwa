/* global React */
const { useState } = React;
const { Card, Avatar, Badge, Button, Icon } = window.UI;

const THREADS = [
  { id: 1, from: 'Familie Huber', subject: 'Lena ist krank', preview: 'Liebes Mikiwa-Team, Lena hat heute Fieber und bleibt zu Hause…', time: '08:14', unread: true },
  { id: 2, from: 'Familie Steiner', subject: 'Abholung früher', preview: 'Wir holen Maximilian heute ausnahmsweise schon um 12:30 ab…', time: 'Gestern', unread: true },
  { id: 3, from: 'Familie Klammer', subject: 'Sommerfest – Helfer:in?', preview: 'Sehr gerne helfen wir am Sommerfest beim Buffet…', time: 'Gestern', unread: true },
  { id: 4, from: 'Familie Pirker', subject: 'Re: Waldtag', preview: 'Vielen Dank für die Info – Sophia freut sich sehr.', time: 'Fr', unread: false },
  { id: 5, from: 'Familie Wieser', subject: 'Wechselkleidung', preview: 'Wir haben heute frische Sachen mitgegeben.', time: 'Mi', unread: false },
];

function Messages() {
  const [active, setActive] = useState(1);
  const t = THREADS.find(x => x.id === active);
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 20, height: '100%' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <h2 style={{ margin: 0, fontFamily: 'var(--font-display)', fontWeight: 800, fontSize: 28, letterSpacing: '-0.02em', color: 'var(--fg-1)' }}>Mitteilungen</h2>
          <p style={{ margin: '4px 0 0', color: 'var(--fg-3)', fontSize: 14 }}>3 ungelesene Nachrichten von Eltern</p>
        </div>
        <Button variant="primary" icon="pen-square">Neue Nachricht</Button>
      </div>
      <Card padding={0} style={{ display: 'grid', gridTemplateColumns: '320px 1fr', overflow: 'hidden', minHeight: 480 }}>
        <div style={{ borderRight: '1px solid var(--border-subtle)', display: 'flex', flexDirection: 'column' }}>
          {THREADS.map(th => (
            <button key={th.id} onClick={() => setActive(th.id)} style={{
              textAlign: 'left', padding: '14px 16px', border: 'none', cursor: 'pointer',
              background: active === th.id ? 'var(--accent-soft)' : 'transparent',
              borderBottom: '1px solid var(--border-subtle)',
              display: 'flex', flexDirection: 'column', gap: 4,
              fontFamily: 'var(--font-body)',
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Avatar name={th.from} size={28}/>
                <span style={{ flex: 1, fontWeight: th.unread ? 700 : 500, fontSize: 13, color: 'var(--fg-1)' }}>{th.from}</span>
                <span style={{ fontSize: 11, color: 'var(--fg-4)' }}>{th.time}</span>
                {th.unread && <span style={{ width: 8, height: 8, borderRadius: 999, background: 'var(--coral-500)' }}/>}
              </div>
              <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--fg-1)' }}>{th.subject}</div>
              <div style={{ fontSize: 12, color: 'var(--fg-3)', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{th.preview}</div>
            </button>
          ))}
        </div>
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          <div style={{ padding: '14px 20px', borderBottom: '1px solid var(--border-subtle)', display: 'flex', alignItems: 'center', gap: 12 }}>
            <Avatar name={t.from} size={36}/>
            <div style={{ flex: 1 }}>
              <div style={{ fontWeight: 700, fontSize: 15, color: 'var(--fg-1)' }}>{t.from}</div>
              <div style={{ fontSize: 12, color: 'var(--fg-4)' }}>Mutter von Lena Huber · Gruppe Sonnenblume</div>
            </div>
            <Badge tone="warning">Krankmeldung</Badge>
          </div>
          <div style={{ flex: 1, padding: '20px', display: 'flex', flexDirection: 'column', gap: 14, background: 'var(--bg-canvas)' }}>
            <div style={{ alignSelf: 'flex-start', maxWidth: '70%', background: 'var(--surface)', border: '1px solid var(--border-subtle)', padding: '12px 14px', borderRadius: 'var(--radius-lg)', borderTopLeftRadius: 4 }}>
              <div style={{ fontSize: 14, color: 'var(--fg-1)', lineHeight: 1.55 }}>Liebes Mikiwa-Team, Lena hat heute Fieber und bleibt zu Hause. Voraussichtlich kommt sie Mittwoch wieder. Liebe Grüße, Familie Huber</div>
              <div style={{ fontSize: 11, color: 'var(--fg-4)', marginTop: 6 }}>08:14</div>
            </div>
            <div style={{ alignSelf: 'flex-end', maxWidth: '70%', background: 'var(--accent)', color: 'var(--accent-on)', padding: '12px 14px', borderRadius: 'var(--radius-lg)', borderTopRightRadius: 4 }}>
              <div style={{ fontSize: 14, lineHeight: 1.55 }}>Liebe Familie Huber, gute Besserung an Lena! Wir tragen sie als krank ein. Bei Fragen melden Sie sich gerne.</div>
              <div style={{ fontSize: 11, opacity: 0.7, marginTop: 6 }}>08:21 · Sabine</div>
            </div>
          </div>
          <div style={{ padding: 14, borderTop: '1px solid var(--border-subtle)', display: 'flex', gap: 8, background: 'var(--surface)' }}>
            <input placeholder="Antwort schreiben…" style={{
              flex: 1, padding: '10px 14px', fontSize: 14,
              borderRadius: 'var(--radius-pill)', border: '1px solid var(--border-default)',
              background: 'var(--surface-sunken)', color: 'var(--fg-1)', outline: 'none',
              fontFamily: 'var(--font-body)',
            }}/>
            <Button variant="primary" icon="send">Senden</Button>
          </div>
        </div>
      </Card>
    </div>
  );
}

window.Messages = Messages;
