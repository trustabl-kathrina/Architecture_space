import { AppProviders } from "@/AppProviders";
import { WorkbenchShell } from "@/layout/WorkbenchShell";

export default function App() {
  return (
    <AppProviders>
      <WorkbenchShell />
    </AppProviders>
  );
}
