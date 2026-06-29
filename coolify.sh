#!/usr/bin/env bash
# Coolify provisioning helper — no dashboard clicking.
# Grounded in Coolify API v1 (POST /applications/public, PATCH /applications/{uuid}, GET /deploy).
#
# One-time setup:
#   export COOLIFY_URL="https://coolify.intelligence-amplified.ai"   # your Coolify base
#   export COOLIFY_TOKEN="<Coolify -> Keys & Tokens -> API tokens>"
#   (needs `jq` installed)
#
# Per domain you STILL do the registrar DNS once (no nameserver change):
#   A  @    45.87.41.216
#   A  www  45.87.41.216      # and remove any parking records
#
# Usage:
#   ./coolify.sh apps                         # list apps:  name | uuid | domains
#   ./coolify.sh add-domain <uuid> <domain>   # attach <domain> (+www) to an existing app, redeploy
#   ./coolify.sh new-site   <domain> <giturl> # create a Dockerfile app on :80 for <domain>
#
# Parked-domain flow (one shared holding app): run `apps`, grab the holding uuid, then
# `add-domain <uuid> kinetik-nrg.com`, `add-domain <uuid> esgforsme.co.uk`, ... done.
set -euo pipefail

: "${COOLIFY_URL:?set COOLIFY_URL}"; : "${COOLIFY_TOKEN:?set COOLIFY_TOKEN}"
API="${COOLIFY_URL%/}/api/v1"
AUTH=(-H "Authorization: Bearer ${COOLIFY_TOKEN}" -H "Content-Type: application/json")
api() { curl -fsS "${AUTH[@]}" "$@"; }

cmd_apps() {
  api "$API/applications" | jq -r '.[] | [.name, .uuid, (.fqdn // "-")] | @tsv' | column -t -s $'\t'
}

cmd_add_domain() {
  local uuid="$1" domain="$2" cur new
  cur=$(api "$API/applications/$uuid" | jq -r '.fqdn // ""')
  new=$(printf '%s,https://%s,https://www.%s' "$cur" "$domain" "$domain" \
        | tr ',' '\n' | sed '/^$/d' | sort -u | paste -sd, -)
  echo "domains -> $new"
  api -X PATCH "$API/applications/$uuid" -d "$(jq -n --arg d "$new" '{domains:$d}')" >/dev/null
  echo "deploying..."
  api "$API/deploy?uuid=$uuid&force=false" | jq -r '.message? // "queued"'
}

cmd_new_site() {
  local domain="$1" git="$2" server project
  server=$(api "$API/servers"  | jq -r '.[0].uuid')   # first server; adjust if you have several
  project=$(api "$API/projects" | jq -r '.[0].uuid')
  api -X POST "$API/applications/public" -d "$(jq -n \
    --arg p "$project" --arg s "$server" --arg g "$git" \
    --arg dom "https://$domain,https://www.$domain" '{
      project_uuid:$p, server_uuid:$s, environment_name:"production",
      git_repository:$g, git_branch:"main", build_pack:"dockerfile",
      ports_exposes:"80", domains:$dom, redirect:"both",
      autogenerate_domain:false, instant_deploy:true
    }')" | jq '{uuid, status}'
}

case "${1:-}" in
  apps)        cmd_apps ;;
  add-domain)  cmd_add_domain "${2:?uuid}" "${3:?domain}" ;;
  new-site)    cmd_new_site   "${2:?domain}" "${3:?giturl}" ;;
  *) echo "usage: $0 {apps | add-domain <uuid> <domain> | new-site <domain> <giturl>}"; exit 1 ;;
esac
