import * as esbuild from "esbuild"

await esbuild.build({
  entryPoints: ["app/javascript/application.js"],
  bundle: true,
  sourcemap: true,
  format: "iife",
  outdir: "app/assets/builds",
  publicPath: "/assets",
  loader: {
    ".png": "file",
    ".gif": "file",
    ".jpg": "file",
    ".svg": "file",
    ".woff": "file",
    ".woff2": "file",
    ".ttf": "file",
    ".eot": "file",
  },
  define: {
    global: "window",
  },
})
