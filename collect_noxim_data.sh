#!/bin/bash

set -e

REPEATS=1
FILE_NAME='noxim_data'
NOXIM_INSTALL_PATH=$HOME"/noxim"

while [[ $# -gt 0 ]]; do
  case $1 in
    -f|--file)
      FILE_NAME="$2"
      shift # past argument
      shift # past value
      ;;
    -e|--executions)
      REPEATS=$2
      shift # past argument
      shift # past value
      ;;
    -np|--noxim-path)
      NOXIM_INSTALL_PATH="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      echo "Usage: .\\$(basename "$0") [-h] [-f | --file FILE_NAME] [-e | --executions EXECUTIONS]"
      echo "Run Noxim network on chip simulator, save data output to csv and plot using python script."
      echo
      echo "Parameters:"
      echo "    -h, --help          Show this help text."
      echo "    -f, --file          File name, without extension, that will be created to store the output from noxim. Default=noxim_data"
      echo "    -e, --executions    Number of times that noxim will be executed for the same configuration. Default=1"
      echo "    -np, --noxim-path   Noxim installation path. Default=\$HOME/noxim"
      exit
      ;;
    -*|--*)
      echo "Unknown option $1"
      echo "Try: '.\\$(basename "$0") --help' for more information."
      exit 1
      ;;
  esac
done

# Guarantee that a file will not be overwritten
if [[ -e $FILE_NAME.csv || -L $FILE_NAME.csv ]] ; then
    i=1
    while [[ -e $FILE_NAME"_"$i.csv || -L $FILE_NAME"_"$i.csv ]] ; do
        let i++
    done
    FILE_NAME=$FILE_NAME"_"$i
fi
FILE_NAME=$FILE_NAME.csv

function cleanup {
    rm raw_data.tmp
}
trap cleanup ERR EXIT

NOXIM_PATH=$NOXIM_INSTALL_PATH"/bin/noxim"
CONFIG_YAML=$NOXIM_INSTALL_PATH"/config_examples/default_config.yaml"
POWER_YAML=$NOXIM_INSTALL_PATH"/bin/power.yaml"

ROUTING_ALGOS="XY WEST_FIRST NORTH_LAST NEGATIVE_FIRST ODD_EVEN"

# INJECTION_RATES="0.001 0.002 0.004 0.008 0.016 0.032 0.064 0.128 0.256 0.512 1"
# INJECTION_RATES="0.001 0.021 0.041 0.061 0.081 0.101 0.121 0.141 0.161 0.181 0.201 0.221 0.241 0.261 0.281 0.301 0.321 0.341 0.361 0.381 0.401 0.421 0.441 0.461 0.481 0.5"
INJECTION_RATES="0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.01  0.011 0.012 0.013 0.014 0.015 0.016 0.017 0.018 0.019 0.02  0.021 0.022 0.023 0.024 0.025 0.026 0.027 0.028 0.029 0.03  0.031 0.032 0.033 0.034 0.035 0.036 0.037 0.038 0.039 0.04  0.041 0.042 0.043 0.044 0.045 0.046 0.047 0.048 0.049 0.05"

CSV_HEADER="route,pir,total_rec_packtess,tota_rec_flits,rec_ideal_flits_ratio,avg_wireless_util,global_avg_delay_cycles,max_delay_cycles,network_throuput,avg_ip_throuput,total_energy,dynamic_energy,static_energy"
# declare -i repeats=5

echo $CSV_HEADER > $FILE_NAME

for route in $ROUTING_ALGOS; do
    echo "Simulating route "$route
    for pir in $INJECTION_RATES; do
        for ((i=0; i<$REPEATS; i++)); do
            # echo "Simulating route "$route" with pir "$pir
            $NOXIM_PATH -config $CONFIG_YAML -power $POWER_YAML -pir $pir poisson -routing $route 2> /dev/null | grep % > raw_data.tmp
            
            data=$route","$pir
            while read -r line; do
                value=$(cut -d ":" -f2- <<< $line | xargs)
                data=$data","$value
            done < raw_data.tmp
            echo $data >> $FILE_NAME
        done
    done
done

python3 plot_noxim_data.py --file $FILE_NAME

