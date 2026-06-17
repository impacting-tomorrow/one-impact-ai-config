# ============================================================================
# Dockerfile — brand the official LibreChat image with Impacting Tomorrow's
# logo & favicon, fetched from URLs at BUILD time.
# ----------------------------------------------------------------------------
# Not a fork. Starts FROM the official prebuilt image and overlays your assets.
# `ADD <url>` makes Docker download the file during build, so you don't need
# curl/wget in the image and don't need to commit any image files to the repo.
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

# Logo (SVG) — shown in the app header / login screen.
ADD https://impactingtomorrow.com/wp-content/uploads/2024/06/New-Logo-Horizontal-1.svg \
    /app/client/dist/assets/logo.svg

# Favicon (PNG) — dropped in at both sizes the app references.
ADD https://impactingtomorrow.com/wp-content/uploads/2024/03/favicon.png \
    /app/client/dist/assets/favicon-32x32.png
ADD https://impactingtomorrow.com/wp-content/uploads/2024/03/favicon.png \
    /app/client/dist/assets/favicon-16x16.png

# ADD-from-URL files default to mode 600; make them world-readable so the app
# can serve them regardless of which user it runs as.
RUN chmod 644 /app/client/dist/assets/logo.svg \
              /app/client/dist/assets/favicon-16x16.png \
              /app/client/dist/assets/favicon-32x32.png

# ---------------------------------------------------------------------------
# OPTIONAL: brand the login button (and accent colors) WITHOUT a full rebuild.
# LibreChat's colors are CSS variables, so this injects a small stylesheet that
# overrides them at runtime.
#
# >>> Set ONE value: replace #6B2C91 with Impacting Tomorrow's purple hex. <<<
# The hover/active variants derive automatically from it via color-mix(), so
# you don't pick the darker shades yourself. (color-mix is supported in all
# current browsers.) Get the exact hex from WordPress: Elementor > Site
# Settings > Global Colors, or use your browser's color picker on the logo.
#
# The default login/submit button is green, so the green tokens point at your
# purple; the button[type=submit] rule is a fallback. The `if` guard means a
# wrong path just skips this step instead of failing the build.
# ---------------------------------------------------------------------------
RUN if [ -f /app/client/dist/index.html ]; then \
      sed -i 's|</head>|<style>:root{--it-purple:#6B2C91;--green-500:var(--it-purple)!important;--green-600:color-mix(in srgb,var(--it-purple) 85%,black)!important;--green-700:color-mix(in srgb,var(--it-purple) 72%,black)!important}button[type=submit]{background-color:var(--it-purple)!important;border-color:var(--it-purple)!important}</style></head>|' /app/client/dist/index.html; \
    fi

# If your base image normally runs as a non-root user and you want to keep that
# at runtime, uncomment the next line. If the app fails to start, remove it.
# USER node