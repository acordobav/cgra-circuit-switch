#!/bin/bash

# Configuración de contraseñas (CAMBIA ESTAS)
PROXY_PASSWORD="Proxy Passwd"
KRIA_PASSWORD="Kria Passwd"

DEST="ubuntu@192.168.1.82:/home/ubuntu/cgra_prj/"
PROXY_USER="fpgaitcr"
PROXY_HOST="4.tcp.ngrok.io"
PROXY_PORT="12867"

echo "Buscando bitstreams disponibles..."
echo

mapfile -t BITFILES < <(find . -name "*.bit")

select BITFILE in "${BITFILES[@]}"; do
    if [ -n "$BITFILE" ]; then
        break
    else
        echo "Selección inválida"
    fi
done

echo
echo "Bitstream seleccionado:"
echo "$BITFILE"
echo

read -p "¿Desea copiar este archivo a la Kria? (Y/n): " confirm
confirm=${confirm:-Y}  # Si está vacío (solo Enter), asigna "Y"

if [[ $confirm == "y" || $confirm == "Y" ]]; then
    echo "Copiando bitstream..."
    
    # Paso 1: Copiar al proxy
    echo "  -> Copiando al proxy..."
    sshpass -p "$PROXY_PASSWORD" scp -P $PROXY_PORT \
        -o StrictHostKeyChecking=no \
        "$BITFILE" ${PROXY_USER}@${PROXY_HOST}:/tmp/
    
    # Paso 2: Desde el proxy a la Kria
    echo "  -> Copiando a la Kria..."
    sshpass -p "$PROXY_PASSWORD" ssh -p $PROXY_PORT \
        -o StrictHostKeyChecking=no \
        ${PROXY_USER}@${PROXY_HOST} \
        "sshpass -p '$KRIA_PASSWORD' scp /tmp/$(basename $BITFILE) $DEST"
    
    if [ $? -eq 0 ]; then
        echo "Transferencia completada."
    else
        echo "Error en la transferencia."
    fi
else
    echo "Operación cancelada."
fi