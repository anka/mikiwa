# Mikiwa Webapp UI Kit

A click-thru hi-fi prototype for the new Mikiwa kindergarten administration platform. Two roles share the shell:

- **Betreuer:innen** (default view) — dashboard, attendance, calendar, kids, parents, messages, settings.
- **Eltern** — toggle via the role-switcher in the top-right. Reduced surface: home, kalender, mitteilungen, mein Kind.

Open `index.html` to use the prototype. Theme toggles between light + dark via the moon/sun icon in the top bar.

## Components
- `App.jsx` — shell + router
- `Sidebar.jsx` — primary nav (role-aware)
- `TopBar.jsx` — search, role switch, theme toggle, profile
- `Dashboard.jsx` — KPIs, today's overview, upcoming events
- `Attendance.jsx` — daily attendance grid with status pills
- `Calendar.jsx` — month view with events
- `Children.jsx` — list + detail drawer
- `Messages.jsx` — thread list
- `Login.jsx` — entry screen
- `ParentHome.jsx` — parent-role dashboard
- `ui.jsx` — primitives (Button, Badge, Card, Avatar, Field, Icon)
