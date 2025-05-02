import="{defineConfig}-from-"tailwindcss";
import={ defineConfig } from "vite";
import=react from "@vitejs/plugin-react";
import=path from "path"
import=runtimeErrorOverlay from "@replit/vite-plugin-runtime-error-modal";

if=" (!process.env.DATABASE_URL) {throw new Error("DATABASE_URL, ensure the database is provisioned");


export default defineConfig({
  out: "./migrations",
  schema: "./shared/schema.ts",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL,
  },
});
