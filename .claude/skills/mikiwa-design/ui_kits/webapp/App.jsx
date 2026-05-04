/* global React, Sidebar, TopBar, Dashboard, Attendance, Calendar, Messages, ParentHome, Children, ChildDetail, ChildForm, FormShowcase */
const { useState, useEffect } = React;

const TITLES = {
  dashboard: 'Übersicht',
  attendance: 'Anwesenheit',
  calendar: 'Kalender',
  children: 'Kinder',
  'children-detail': 'Kind',
  'children-new': 'Neues Kind',
  'children-edit': 'Kind bearbeiten',
  parents: 'Eltern',
  messages: 'Mitteilungen',
  forms: 'Formularfelder',
  settings: 'Einstellungen',
  'parent-home': 'Start',
  'parent-calendar': 'Kalender',
  'parent-messages': 'Mitteilungen',
  'parent-child': 'Mein Kind',
};

// Map detail/edit/new sub-routes back to their nav-item id so the sidebar stays selected.
const NAV_OF = {
  'children-detail': 'children',
  'children-new': 'children',
  'children-edit': 'children',
};

function App() {
  const [role, setRole] = useState('staff');
  const [theme, setTheme] = useState('light');
  const [route, setRoute] = useState('dashboard');
  const [routeArg, setRouteArg] = useState(null);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
  }, [theme]);

  const navigate = (r, arg = null) => { setRoute(r); setRouteArg(arg); };

  const handleRole = (r) => {
    setRole(r);
    setRoute(r === 'staff' ? 'dashboard' : 'parent-home');
    setRouteArg(null);
  };

  const renderRoute = () => {
    if (role === 'staff') {
      switch (route) {
        case 'dashboard': return <Dashboard/>;
        case 'attendance': return <Attendance/>;
        case 'calendar': return <Calendar/>;
        case 'messages': return <Messages/>;
        case 'children': return <Children navigate={navigate}/>;
        case 'children-detail': return <ChildDetail navigate={navigate} childId={routeArg}/>;
        case 'children-new': return <ChildForm navigate={navigate} mode="new"/>;
        case 'children-edit': return <ChildForm navigate={navigate} mode="edit" childId={routeArg}/>;
        case 'forms': return <FormShowcase navigate={navigate}/>;
        default: return <Placeholder name={TITLES[route]}/>;
      }
    } else {
      switch (route) {
        case 'parent-home': return <ParentHome/>;
        case 'parent-calendar': return <Calendar/>;
        case 'parent-messages': return <Messages/>;
        default: return <Placeholder name={TITLES[route]}/>;
      }
    }
  };

  // The sidebar highlights its parent nav for sub-routes.
  const navRoute = NAV_OF[route] || route;
  const setRouteFromSidebar = (r) => navigate(r);

  return (
    <div style={{ display: 'flex', minHeight: '100vh', background: 'var(--bg-app)' }}>
      <Sidebar role={role} route={navRoute} setRoute={setRouteFromSidebar}/>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <TopBar role={role} setRole={handleRole} theme={theme} setTheme={setTheme} title={TITLES[route] || ''}/>
        <main style={{ padding: 32, flex: 1, overflow: 'auto' }}>
          {renderRoute()}
        </main>
      </div>
    </div>
  );
}

function Placeholder({ name }) {
  return (
    <div style={{ padding: 64, textAlign: 'center', color: 'var(--fg-3)' }}>
      <img src="../../assets/illustration-empty.svg" alt="" style={{ maxWidth: 320 }}/>
      <h2 style={{ marginTop: 12, color: 'var(--fg-1)' }}>{name}</h2>
      <p style={{ fontSize: 14 }}>Diese Ansicht ist im Prototyp angedeutet, aber noch nicht ausgebaut.</p>
    </div>
  );
}

window.App = App;
