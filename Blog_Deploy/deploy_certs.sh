#!/bin/sh
pathtoyourcertsdir="/home/nginx"
domain="site_prefix.site_domain"
basedomain="$(basename $RENEWED_LINEAGE)"
youruser="nginx"
yourgroup="nginx"

if [ "$domain" = "$basedomain" ];then
    cp "$RENEWED_LINEAGE/fullchain.pem" "$pathtoyourcertsdir/server_cert.pem"
    cp "$RENEWED_LINEAGE/privkey.pem" "$pathtoyourcertsdir/server_key.pem"
    chown $youruser:$yourgroup "$pathtoyourcertsdir/server_cert.pem"
    chown $youruser:$yourgroup "$pathtoyourcertsdir/server_key.pem"
    sudo nginx -t && systemctl reload nginx
fi
