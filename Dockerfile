FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
# Per-Host "coming soon" on :80 (matches Coolify Ports Exposes=80).
# One resource backs every parked domain — just add each domain in Coolify's
# Domains field. Give a domain a nicer name via the map in default.conf.
