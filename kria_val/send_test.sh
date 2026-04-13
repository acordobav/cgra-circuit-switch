#!/bin/bash

PROXY_PASSWORD="Proxy Passwd"
KRIA_PASSWORD="Kria Passwd"
DEST="ubuntu@192.168.1.82:/home/ubuntu/cgra_prj/"
PROXY_USER="fpgaitcr"
PROXY_HOST="4.tcp.ngrok.io"
PROXY_PORT="12867"

function send_test() {
    echo "Buscando archivos *test.c ..."
    mapfile -t TESTFILES < <(find . -name "*test.c")
    
    if [ ${#TESTFILES[@]} -eq 0 ]; then
        echo "No se encontraron archivos *test.c"
        exit 1
    fi
    
    select FILE in "${TESTFILES[@]}"; do
        if [ -n "$FILE" ]; then
            echo "Enviando $FILE a la Kria..."
            
            # Paso 1: Copiar al proxy
            sshpass -p "$PROXY_PASSWORD" scp -P $PROXY_PORT \
                -o StrictHostKeyChecking=no \
                "$FILE" ${PROXY_USER}@${PROXY_HOST}:/tmp/
            
            # Paso 2: Desde el proxy a la Kria
            sshpass -p "$PROXY_PASSWORD" ssh -p $PROXY_PORT \
                -o StrictHostKeyChecking=no \
                ${PROXY_USER}@${PROXY_HOST} \
                "sshpass -p '$KRIA_PASSWORD' scp /tmp/$(basename $FILE) $DEST"
            
            break
        else
            echo "Selección inválida"
        fi
    done
}

function send_prog() {
    FILE="prog_test_kria.sh"
    
    if [ ! -f "$FILE" ]; then
        echo "No se encontró $FILE"
        exit 1
    fi
    
    echo "Enviando $FILE a la Kria..."
    
    sshpass -p "$PROXY_PASSWORD" scp -P $PROXY_PORT \
        -o StrictHostKeyChecking=no \
        "$FILE" ${PROXY_USER}@${PROXY_HOST}:/tmp/
    
    sshpass -p "$PROXY_PASSWORD" ssh -p $PROXY_PORT \
        -o StrictHostKeyChecking=no \
        ${PROXY_USER}@${PROXY_HOST} \
        "sshpass -p '$KRIA_PASSWORD' scp /tmp/$(basename $FILE) $DEST"
}

case "$1" in
    -t)
        send_test
        ;;
    -p)
        send_prog
        ;;
    *)
        echo "Uso:"
        echo "./send_test.sh -t   (enviar *test.c)"
        echo "./send_test.sh -p   (enviar prog_test_kria.sh)"
        ;;
esac

if [ $? -eq 0 ]; then
    echo "Transferencia completada."
else
    echo "Error al copiar el archivo."
fi