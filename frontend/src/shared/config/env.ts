/**
 * Typed access to Vite environment variables with safe defaults.
 */
export const env = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? "/api/v1",
  wsBaseUrl: import.meta.env.VITE_WS_BASE_URL ?? "ws://127.0.0.1:8000/ws",
  appName: import.meta.env.VITE_APP_NAME ?? "KEW",
} as const;
