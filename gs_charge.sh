#!/bin/bash

input=$1
# Number of atoms
NAtoms=`grep 'NAtoms' "$input" | sed 's/^ *//' | awk -F'[ ]+' '{print $2}' | head -1`

# Get line number for a matched line
function get_line ()
{
    keywords=$1
    # cut with delimiter ":"
    grep -n "$keywords" "$input" | cut -f1 -d:
}

# Return a 2N array, element, charge = Array[2*i], Array[2*i+1]; i = 0:N
function get_nao ()
{
    # line outputing NAO
    nao_line=`get_line "Summary\ of\ Natural\ Population" | tail -1`

    # NAO starts after 6 lines
    nao_line_start=$((nao_line+6))
    nao_line_end=$((nao_line_start+NAtoms-1))

    # Output NAO with element symbol
    sed -n "$nao_line_start, $nao_line_end p" "$input" | sed 's/^ *//' | awk -F'[ ]+' '{printf"%12s %12.6f", $1, $3}'
}

function get_esp ()
{
    # match ESP printing section
    esp_line=`get_line "Charges\ from\ ESP\ fit\," | tail -1`

    # ESP fit charge prints after three lines
    esp_line_start=$((esp_line+3))
    esp_line_end=$((esp_line_start+NAtoms-1))

    # output NAO
    sed -n "$esp_line_start, $esp_line_end p" "$input" | sed 's/^ *//' | awk -F'[ ]+' '{printf"%12s %12.6f", $2, $3}'
}

function get_mulliken ()
{
    # match mulliken printing section
    mlk_line=`get_line "Mulliken\ atomic\ charges" | tail -1`

    # mulliken fit charge prints after three lines
    mlk_line_start=$((mlk_line+2))
    mlk_line_end=$((mlk_line_start+NAtoms-1))

    # output NAO
    sed -n "$mlk_line_start, $mlk_line_end p" "$input" | sed 's/^ *//' | awk -F'[ ]+' '{printf"%12s %12.6f", $2, $3}'
}

opt=$2
case "$opt" in
    "esp")
    ele_chg=(`get_esp`)
    echo "ESP fitting charges:"
    ;;
    "npa")
    ele_chg=(`get_nao`)
    echo "NPA charges:"
    ;;
    "mulliken")
    ele_cng=(`get_mulliken`)
    echo "Mulliken charges:"
    ;;
    *) echo "unknown options!"
    ;;
    esac

for ((i=0;i<$NAtoms;i++));
do
    element=${ele_chg[$((i*2))]}
    charge=${ele_chg[$((i*2+1))]}
    printf "%s\t %8.4f \n" $element $charge
done

