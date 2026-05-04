/* global React */
const { Icon, Button } = window.UI;

/**
 * PageHeader — primary metaphor for screen titles + action placement.
 *
 * Layout follows the mikiwa design metaphor (see screenshot reference):
 *   ┌──────────────────────────────────────────────────────────────────┐
 *   │ Title                       [secondary text-buttons] [primary]   │
 *   │                                          [back link →]           │
 *   └──────────────────────────────────────────────────────────────────┘
 *
 * Rules:
 *  - Title is large (h2), sentence-case, NEVER bold-shouty.
 *  - Actions sit top-right, right-aligned, in a single horizontal group.
 *  - The "primary" action of THIS page (Bearbeiten on a view, Speichern on
 *    a form) is the only outlined / filled button. Everything else is a
 *    text+icon ghost button.
 *  - Destructive actions (Absagen, Löschen) live in this same row, NOT in
 *    a hidden menu — but rendered as plain text-buttons in the danger
 *    color, with no fill.
 *  - "Zurück" is always the rightmost item, ghost, no icon.
 *  - On `new` / `edit` pages, swap the action group to: [Abbrechen] [Speichern primary].
 */
function PageHeader({ title, subtitle, primary, secondary = [], back }) {
  return (
    <div style={{
      display: 'flex',
      alignItems: 'flex-start',
      justifyContent: 'space-between',
      gap: 24,
      paddingBottom: 20,
      borderBottom: '1px solid var(--border-subtle)',
      marginBottom: 24,
    }}>
      <div style={{ minWidth: 0, flex: 1, overflow: 'hidden' }}>
        <h2 style={{
          margin: 0,
          fontFamily: 'var(--font-display)',
          fontWeight: 800,
          fontSize: 28,
          letterSpacing: '-0.02em',
          color: 'var(--fg-1)',
          whiteSpace: 'nowrap',
          overflow: 'hidden',
          textOverflow: 'ellipsis',
        }}>{title}</h2>
        {subtitle && <p style={{ margin: '4px 0 0', color: 'var(--fg-3)', fontSize: 14 }}>{subtitle}</p>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4, flexShrink: 0 }}>
        {secondary.map((a, i) => (
          <TextButton key={i} {...a}/>
        ))}
        {primary && <Button variant="secondary" icon={primary.icon} onClick={primary.onClick}>{primary.label}</Button>}
        {back && <TextButton label={back.label || 'Zurück'} onClick={back.onClick}/>}
      </div>
    </div>
  );
}

/**
 * TextButton — the ghost text+icon button used in PageHeader action rows.
 * Icon left, label right. No background. No border. Hover reveals subtle bg.
 */
function TextButton({ icon, label, tone = 'default', onClick }) {
  const colors = {
    default: 'var(--fg-2)',
    danger: 'var(--danger)',
  };
  return (
    <button onClick={onClick} style={{
      display: 'inline-flex',
      alignItems: 'center',
      gap: 6,
      padding: '8px 10px',
      whiteSpace: 'nowrap',
      background: 'transparent',
      border: 'none',
      borderRadius: 'var(--radius-pill)',
      color: colors[tone],
      fontFamily: 'var(--font-body)',
      fontSize: 14,
      fontWeight: 600,
      cursor: 'pointer',
      transition: 'background 120ms var(--ease-soft)',
    }}
    onMouseEnter={e => e.currentTarget.style.background = 'var(--surface-hover)'}
    onMouseLeave={e => e.currentTarget.style.background = 'transparent'}
    >
      {icon && <Icon name={icon} size={14}/>}
      {label}
    </button>
  );
}

window.PageHeader = PageHeader;
window.TextButton = TextButton;
