#!/bin/sh
pathtoyourcertsdir="/home/nginx"
domain="site_prefix.site_domain"
basedomain="$(basename $RENEWED_LINEAGE)"
youruser="nginx"
yourgroup="nginx"

if [ "$domain" = "$basedomain" ];then
    cp "$RENEWED_LINEAGE/fullchain.pem" "$pathtoyourcertsdir/fullchain.pem"
    cp "$RENEWED_LINEAGE/privkey.pem" "$pathtoyourcertsdir/privkey.pem"
    cp "$RENEWED_LINEAGE/chain.pem" "$pathtoyourcertsdir/chain.pem"
    chown $youruser:$yourgroup "$pathtoyourcertsdir/fullchain.pem"
    chown $youruser:$yourgroup "$pathtoyourcertsdir/privkey.pem"
    chown $youruser:$yourgroup "$pathtoyourcertsdir/chain.pem"
    sudo nginx -t && systemctl reload nginx
fi

