#!/usr/bin/env bash
set -euo pipefail

# PHP_MEMORY_LIMIT="${PHP_MEMORY_LIMIT:-1024M}"
# MAX_MESSAGES="${MAX_MESSAGES:-0}"
CONSUMERS="${CONSUMERS:-async.operations.all}"
USER_NAME="${RUN_AS_USER:-app}"
WORKDIR="${WORKDIR:-/var/www/html}"
LOGDIR="${LOGDIR:-/var/www/html/var/log/magento-consumers}"


if [ ! -f "${WORKDIR}/bin/magento" ]; then
  echo "No s'ha trobat ${WORKDIR}/bin/magento a ${WORKDIR}. Revisa el bind-mount."
  exit 1
fi

cd "$WORKDIR"

i=0
IFS=',' read -ra LIST <<< "$CONSUMERS"
for c in "${LIST[@]}"; do
  c_trim="$(echo "$c" | xargs)"
  [ -z "$c_trim" ] && continue
  cat > "/etc/supervisor/conf.d/consumer_${c_trim}.conf" <<EOF
[program:magento-consumer-${c_trim}]
directory=${WORKDIR}
command=php -d memory_limit=${PHP_MEMORY_LIMIT} bin/magento queue:consumers:start ${c_trim}
user=${USER_NAME}
autostart=true
autorestart=true
startretries=999
startsecs=1
stopwaitsecs=15
killasgroup=true
stopsignal=TERM
stdout_logfile=${LOGDIR}/consumer_${c_trim}.log
stdout_logfile_maxbytes=0
stderr_logfile=${LOGDIR}/consumer_${c_trim}.err
stderr_logfile_maxbytes=0
environment=COMPOSER_DISABLE_XDEBUG_WARN=1,APP_ENV="prod"
EOF
  i=$((i+1))
done

echo "Iniciant supervisord amb $(ls /etc/supervisor/conf.d | wc -l) consumers..."
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
