FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
# Coolify builds this and routes :80 -> rsorourke.com via its proxy (TLS auto).
