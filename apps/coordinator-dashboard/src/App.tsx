import { useEffect, useState } from "react";
import { Layout } from "./components/Layout";
import { AccountPage } from "./pages/AccountPage";
import { CapturePage } from "./pages/CapturePage";
import { DashboardPage } from "./pages/DashboardPage";
import { LoginPage } from "./pages/LoginPage";
import { MapPage } from "./pages/MapPage";
import { TasksPage } from "./pages/TasksPage";
import { VolunteersPage } from "./pages/VolunteersPage";
import { useAppState } from "./state/AppStateContext";

type AppRoute =
  | "/dashboard"
  | "/capture"
  | "/tasks"
  | "/volunteers"
  | "/map"
  | "/account";

const validRoutes = new Set<AppRoute>([
  "/dashboard",
  "/capture",
  "/tasks",
  "/volunteers",
  "/map",
  "/account"
]);

function readRoute(): AppRoute {
  const hashRoute = window.location.hash.replace(/^#/, "") as AppRoute;
  return validRoutes.has(hashRoute) ? hashRoute : "/dashboard";
}

export function App() {
  const { loading, session } = useAppState();
  const [route, setRoute] = useState<AppRoute>(readRoute);

  useEffect(() => {
    const onHashChange = () => {
      setRoute(readRoute());
    };

    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);

  function navigate(nextRoute: AppRoute) {
    window.location.hash = nextRoute;
    setRoute(nextRoute);
  }

  if (loading) {
    return (
      <div className="loading-shell">
        <div className="loading-card">
          <div className="brand-mark">GG</div>
          <strong>Connecting to Firebase...</strong>
        </div>
      </div>
    );
  }

  if (!session) {
    return <LoginPage />;
  }

  let page = <DashboardPage />;
  if (route === "/capture") {
    page = <CapturePage onSaved={() => navigate("/dashboard")} />;
  } else if (route === "/tasks") {
    page = <TasksPage />;
  } else if (route === "/volunteers") {
    page = <VolunteersPage />;
  } else if (route === "/map") {
    page = <MapPage />;
  } else if (route === "/account") {
    page = <AccountPage />;
  }

  return (
    <Layout currentRoute={route} navigate={navigate}>
      {page}
    </Layout>
  );
}
