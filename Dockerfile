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
