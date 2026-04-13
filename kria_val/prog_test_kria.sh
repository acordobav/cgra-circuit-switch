#!/bin/bash

echo "================================="
echo "   KRIA FPGA TEST TOOL"
echo "================================="

echo
echo "Seleccione una opción:"
echo "1) Programar FPGA (.bit)"
echo "2) Compilar y ejecutar test (*test.c)"
echo "3) Desprogramar FPGA"
echo "4) Salir"
echo

read -p "Opción: " opt

case $opt in

1)
    echo
    echo "Buscando bitstreams..."
    mapfile -t BITFILES < <(find . -name "*.bit")

    if [ ${#BITFILES[@]} -eq 0 ]; then
        echo "No se encontraron bitstreams."
        exit 1
    fi

    select BITFILE in "${BITFILES[@]}"; do
        if [ -n "$BITFILE" ]; then
            echo "Programando FPGA con $BITFILE"
            sudo fpgautil -b "$BITFILE"
            break
        else
            echo "Selección inválida"
        fi
    done
;;

2)
    echo
    echo "Buscando tests..."

    mapfile -t TESTFILES < <(find . -name "*test.c")

    if [ ${#TESTFILES[@]} -eq 0 ]; then
        echo "No se encontraron archivos *test.c"
        exit 1
    fi

    select TESTFILE in "${TESTFILES[@]}"; do
        if [ -n "$TESTFILE" ]; then

            EXE=$(basename "$TESTFILE" .c)

            echo
            echo "Compilando $TESTFILE..."
            gcc "$TESTFILE" -o "$EXE"

            if [ $? -ne 0 ]; then
                echo "Error de compilación."
                exit 1
            fi

            echo
            echo "Ejecutando $EXE..."
            sudo ./"$EXE"

            break
        else
            echo "Selección inválida"
        fi
    done
;;

3)
    echo
    echo "Desprogramando FPGA..."
    sudo fpgautil -R
;;

4)
    echo "Saliendo..."
;;

*)
    echo "Opción inválida."
;;

esac