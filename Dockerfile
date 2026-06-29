FROM nginx:alpine
COPY default.conf /etc/nginx/conf.d/default.conf
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 3000
# nginx listens on 3000 to match Coolify's default "Ports Exposes" — no UI change needed.
