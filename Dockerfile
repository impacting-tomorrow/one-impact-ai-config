# ============================================================================
# Dockerfile — brand the official LibreChat image with Impacting Tomorrow's
# logo, favicon & Catalyst icon at BUILD time.
# ----------------------------------------------------------------------------
# Not a fork. Starts FROM the official prebuilt image and overlays your assets.
# All brand assets live in this repo under ./logos and are COPYed in at build
# time (the build context is the repo root) — nothing is fetched from the web,
# so the build is self-contained and reproducible.
#
# DEPLOY ON RENDER:  New > Web Service > point at the repo containing this
# Dockerfile, Runtime = Docker. Set your env vars (APP_TITLE, MONGO_URI,
# CONFIG_PATH, the Catalyst OAuth vars, etc.) on that service.
#
# IMPORTANT: do NOT put this in Render's "Pre-Deploy Command" — pre-deploy
# filesystem changes are discarded before the service goes live.
# ============================================================================

# Pin to a specific release for stability instead of :latest when you can.
FROM ghcr.io/danny-avila/librechat:latest

# Do the asset swap as root so we can write into the app dir and set perms.
# (Harmless if the image already runs as root.)
USER root

# Header / login logo. The app loads /assets/logo.svg as image/svg+xml via an
# <img>, which is sandboxed from the page (Tailwind's `dark:` / the `.dark`
# class can't reach inside it). So we ship TWO true-vector variants traced from
# logos/catalyst-square-logo.png (mark + "catalyst" wordmark, tagline dropped):
#   logo.svg       — navy wordmark, for the light theme
#   logo-dark.svg  — white wordmark, for the dark theme
# LibreChat's dark mode is the `.dark` class on <html>, so the CSS injected into
# index.html below swaps the <img>'s rendered image to logo-dark.svg under
# `.dark`. That makes the logo follow the IN-APP theme toggle (not the OS).
# Regenerate both from the source PNG with vtracer + the wordmark-recolor step.
COPY logos/logo.svg      /app/client/dist/assets/logo.svg
COPY logos/logo-dark.svg /app/client/dist/assets/logo-dark.svg

# Favicon (PNG) — from the repo, dropped in at both sizes the app references.
# Also reused as the Catalyst MCP server icon via iconPath in librechat.yaml.
COPY logos/favicon.png /app/client/dist/assets/favicon-32x32.png
COPY logos/favicon.png /app/client/dist/assets/favicon-16x16.png

# COPYed files inherit host perms; normalize to world-readable so the app can
# serve them regardless of which user it runs as.
RUN chmod 644 /app/client/dist/assets/logo.svg \
              /app/client/dist/assets/logo-dark.svg \
              /app/client/dist/assets/favicon-16x16.png \
              /app/client/dist/assets/favicon-32x32.png

# ---------------------------------------------------------------------------
# OPTIONAL: re-skin LibreChat's green to your brand purple WITHOUT a rebuild.
# This injects a stylesheet just before </head> that recolors green two ways:
#
#   1. The CSS-variable ramp (--green-50 ... --green-950) — used by most of the
#      app's chrome — remapped to a purple ramp derived from one base value.
#   2. The literal Tailwind green UTILITY CLASSES (text-green-*, bg-green-*,
#      focus:border-green-*, *-decoration-green-*, etc). These compile to
#      hard-coded rgb() values in the CSS bundle and DON'T read the variables
#      above, so the ramp alone can't touch them. These are exactly the stray
#      greens you'd otherwise still see: the "Terms of service" link and the
#      input hover/focus border. We match them with [class*="..."] selectors so
#      we don't have to enumerate every shade/state. Links need BOTH `color`
#      and `-webkit-text-fill-color` — their visible color comes from text-fill,
#      which defaults to the (green) color, so setting color alone does nothing.
#
# >>> Set ONE value: replace #61366E with Impacting Tomorrow's purple hex. <<<
# Lighter/darker shades are derived automatically via color-mix() (supported in
# all current browsers). Get the exact hex from WordPress: Elementor > Site
# Settings > Global Colors, or a browser color picker on the logo.
#
# If a stray element is STILL green after this, it's using a literal color from
# an even more specific rule; inspect it in devtools and add a targeted rule.
# The `if` guard means a wrong path skips this step instead of failing the build.
# ---------------------------------------------------------------------------
RUN if [ -f /app/client/dist/index.html ]; then \
      sed -i 's|</head>|<style>:root{--it-purple:#61366E;--green-50:color-mix(in srgb,var(--it-purple) 8%,white)!important;--green-100:color-mix(in srgb,var(--it-purple) 16%,white)!important;--green-200:color-mix(in srgb,var(--it-purple) 30%,white)!important;--green-300:color-mix(in srgb,var(--it-purple) 50%,white)!important;--green-400:color-mix(in srgb,var(--it-purple) 75%,white)!important;--green-500:var(--it-purple)!important;--green-600:color-mix(in srgb,var(--it-purple) 85%,black)!important;--green-700:color-mix(in srgb,var(--it-purple) 72%,black)!important;--green-800:color-mix(in srgb,var(--it-purple) 58%,black)!important;--green-900:color-mix(in srgb,var(--it-purple) 45%,black)!important;--green-950:color-mix(in srgb,var(--it-purple) 32%,black)!important}button[type=submit]{background-color:var(--it-purple)!important;border-color:var(--it-purple)!important}[class*="text-green-"]{color:var(--it-purple)!important;-webkit-text-fill-color:var(--it-purple)!important}[class*="bg-green-"]{background-color:var(--it-purple)!important}[class*="fill-green-"]{fill:var(--it-purple)!important}[class*="stroke-green-"]{stroke:var(--it-purple)!important}[class*="focus:border-green"]:focus{border-color:var(--it-purple)!important}[class*="hover:border-green"]:hover{border-color:var(--it-purple)!important}[class*="border-green-"]:not([class*=":border-green"]){border-color:var(--it-purple)!important}[class*="focus:ring-green"]:focus{--tw-ring-color:var(--it-purple)!important}[class*="decoration-green"]:hover,[class*="decoration-green"]:focus{text-decoration-color:var(--it-purple)!important}html.dark img[src$="logo.svg"]{content:url(/assets/logo-dark.svg)}</style></head>|' /app/client/dist/index.html; \
    fi

# If your base image normally runs as a non-root user and you want to keep that
# at runtime, uncomment the next line. If the app fails to start, remove it.
# USER node