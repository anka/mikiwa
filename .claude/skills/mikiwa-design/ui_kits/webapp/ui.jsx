/* global React, lucide */
const { useState, useEffect, useRef } = React;

// ---------- Icon ----------
function Icon({ name, size = 20, color, style }) {
  const ref = useRef(null);
  useEffect(() => {
    if (ref.current && window.lucide) {
      ref.current.innerHTML = '';
      const svg = document.createElement('i');
      svg.setAttribute('data-lucide', name);
      svg.style.width = size + 'px';
      svg.style.height = size + 'px';
      ref.current.appendChild(svg);
      window.lucide.createIcons({ attrs: { width: size, height: size } });
    }
  }, [name, size]);
  return <span ref={ref} style={{ display: 'inline-flex', color, ...(style||{}) }} />;
}

// ---------- Button ----------
function Button({ variant = 'primary', size = 'md', icon, children, onClick, disabled, type = 'button', style }) {
  const sizes = {
    sm: { padding: '6px 12px', fontSize: 13 },
    md: { padding: '10px 18px', fontSize: 14 },
    lg: { padding: '14px 24px', fontSize: 16 },
  };
  const variants = {
    primary: { background: 'var(--accent)', color: 'var(--accent-on)', border: '1px solid transparent' },
    secondary: { background: 'var(--surface)', color: 'var(--fg-1)', border: '1px solid var(--border-default)' },
    ghost: { background: 'transparent', color: 'var(--fg-1)', border: '1px solid transparent' },
    danger: { background: 'var(--danger)', color: '#fff', border: '1px solid transparent' },
  };
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className={`mw-btn mw-btn-${variant}`}
      style={{
        fontFamily: 'var(--font-body)', fontWeight: 600,
        borderRadius: 'var(--radius-pill)',
        cursor: disabled ? 'not-allowed' : 'pointer',
        opacity: disabled ? 0.5 : 1,
        display: 'inline-flex', alignItems: 'center', gap: 8,
        transition: 'all 120ms var(--ease-soft)',
        ...sizes[size], ...variants[variant], ...(style||{})
      }}
    >
      {icon && <Icon name={icon} size={size === 'sm' ? 14 : 16} />}
      {children}
    </button>
  );
}

// ---------- Badge ----------
function Badge({ tone = 'neutral', children, dot, style }) {
  const tones = {
    neutral: { background: 'var(--surface-sunken)', color: 'var(--fg-2)', border: '1px solid var(--border-subtle)' },
    success: { background: 'var(--success-soft)', color: 'var(--success)' },
    info:    { background: 'var(--info-soft)',    color: 'var(--info)' },
    warning: { background: 'var(--warning-soft)', color: 'var(--coral-700)' },
    danger:  { background: 'var(--danger-soft)',  color: 'var(--danger)' },
    accent:  { background: 'var(--accent-soft)',  color: 'var(--sun-800)' },
  };
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 6,
      padding: '3px 9px', borderRadius: 999,
      fontSize: 12, fontWeight: 600,
      ...tones[tone], ...(style||{})
    }}>
      {dot && <span style={{ width: 6, height: 6, borderRadius: 999, background: 'currentColor' }}/>}
      {children}
    </span>
  );
}

// ---------- Card ----------
function Card({ children, style, padding = 18 }) {
  return (
    <div style={{
      background: 'var(--surface)',
      border: '1px solid var(--border-subtle)',
      borderRadius: 'var(--radius-lg)',
      boxShadow: 'var(--shadow-sm)',
      padding,
      ...(style||{})
    }}>{children}</div>
  );
}

// ---------- Avatar ----------
const AVA_COLORS = [
  ['var(--leaf-200)', 'var(--leaf-800)'],
  ['var(--sky-200)',  'var(--sky-800)'],
  ['var(--coral-200)','var(--coral-700)'],
  ['var(--sun-200)',  'var(--sun-800)'],
];
function Avatar({ name = '?', size = 36 }) {
  const initials = name.split(' ').map(s => s[0]).slice(0,2).join('').toUpperCase();
  const idx = (name.charCodeAt(0) + (name.charCodeAt(1)||0)) % AVA_COLORS.length;
  const [bg, fg] = AVA_COLORS[idx];
  return (
    <span style={{
      width: size, height: size, borderRadius: 999,
      background: bg, color: fg,
      display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
      fontWeight: 700, fontSize: size * 0.4,
      border: '2px solid var(--surface)', flexShrink: 0,
    }}>{initials}</span>
  );
}

// ---------- Field ----------
function Field({ label, hint, error, children }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {label && <label style={{ fontSize: 13, fontWeight: 600, color: 'var(--fg-1)' }}>{label}</label>}
      {children}
      {error && <span style={{ fontSize: 12, color: 'var(--danger)', fontWeight: 600 }}>{error}</span>}
      {hint && !error && <span style={{ fontSize: 12, color: 'var(--fg-4)' }}>{hint}</span>}
    </div>
  );
}

function Input(props) {
  return (
    <input
      {...props}
      style={{
        fontFamily: 'var(--font-body)', fontSize: 14,
        padding: '10px 12px',
        borderRadius: 'var(--radius-md)',
        border: '1px solid var(--border-default)',
        background: 'var(--surface)',
        color: 'var(--fg-1)',
        outline: 'none',
        ...(props.style||{})
      }}
    />
  );
}

window.UI = { Icon, Button, Badge, Card, Avatar, Field, Input };
