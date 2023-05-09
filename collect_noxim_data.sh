#!/bin/bash

REPEATS=1
FILE_NAME='data/noxim_data'
NOXIM_INSTALL_PATH=$HOME"/noxim"

while [[ $# -gt 0 ]]; do
	case $1 in
		-f|--file)
			FILE_NAME="data/$2"
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

bar_size=20
bar_char_done="#"
bar_char_todo="-"
bar_percentage_scale=2

function show_progress {
    current="$1"
    total="$2"

    # calculate the progress in percentage 
    percent=$(bc <<< "scale=$bar_percentage_scale; 100 * $current / $total" )
    # The number of done and todo characters
    done=$(bc <<< "scale=0; $bar_size * $percent / 100" )
    todo=$(bc <<< "scale=0; $bar_size - $done" )

    # build the done and todo sub-bars
    done_sub_bar=$(printf "%${done}s" | tr " " "${bar_char_done}")
    todo_sub_bar=$(printf "%${todo}s" | tr " " "${bar_char_todo}")

    # output the bar
    echo -ne "\r\tProgress : [${done_sub_bar}${todo_sub_bar}] ${percent}%"

    if [ $total -eq $current ]; then
		ptime="$3"
        echo -e "  Done in $(( $(date +%s) - ptime )) seconds."
    fi
}

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
	echo ""
	# echo "Performing cleanup."
	rm raw_data.tmp
	echo "Done!"
}
trap cleanup ERR EXIT

NOXIM_PATH=$NOXIM_INSTALL_PATH"/bin/noxim"
CONFIG_YAML=$NOXIM_INSTALL_PATH"/config_examples/default_config.yaml"
POWER_YAML=$NOXIM_INSTALL_PATH"/bin/power.yaml"

ROUTING_ALGOS="XY WEST_FIRST NORTH_LAST NEGATIVE_FIRST ODD_EVEN"
CSV_HEADER="route,pir,total_rec_packtess,tota_rec_flits,rec_ideal_flits_ratio,avg_wireless_util,global_avg_delay_cycles,max_delay_cycles,network_throuput,avg_ip_throuput,total_energy,dynamic_energy,static_energy"

INJECTION_RATES="0.001 0.002 0.003 0.004 0.005 0.006 0.007 0.008 0.009 0.01 0.011 0.012 0.013 0.014 0.015 0.016 0.017 0.018 0.019 0.02 0.021 0.022 0.023 0.024 0.025 0.026 0.027 0.028 0.029 0.03 0.031 0.032 0.033 0.034 0.035 0.036 0.037 0.038 0.039 0.04 0.041 0.042 0.043 0.044 0.045 0.046 0.047 0.048 0.049 0.05"
# INJECTION_RATES="0.02 0.021 0.022 0.023 0.024 0.025 0.026 0.027 0.028 0.029 0.03 0.031 0.032 0.033 0.034 0.035"
# INJECTION_RATES="0.02 0.021 0.022 0.023 0.024 0.025 0.026 0.027 0.028 0.029 0.03 0.031 0.032 0.033 0.034 0.035 0.036 0.037 0.038 0.039 0.04 0.041 0.042 0.043 0.044 0.045 0.046 0.047 0.048 0.049 0.05"

RATES_COUNT=$(echo $INJECTION_RATES | wc -w)
ROUTES_COUNT=$(echo $ROUTING_ALGOS | wc -w)
TOTAL_COUNT=$(( RATES_COUNT * REPEATS ))

echo "Running Noxim with:" 
echo "	$ROUTES_COUNT routing algorithm(s);"
echo "	$RATES_COUNT Packet Injection Rate(s);"
echo "	$REPEATS execution(s) for each PIR;"
echo ""

echo $CSV_HEADER > $FILE_NAME

start=$(date +%s)
for route in $ROUTING_ALGOS; do
	echo "Simulating route "$route
	ptime=$(date +%s)
	count=0
	show_progress $count $TOTAL_COUNT
	for pir in $INJECTION_RATES; do
		for ((i=0; i<$REPEATS; i++)); do
			$NOXIM_PATH -config $CONFIG_YAML -power $POWER_YAML -pir $pir poisson -routing $route 2> /dev/null | grep % > raw_data.tmp
			data=$route","$pir
			while read -r line; do
				value=$(cut -d ":" -f2- <<< $line | xargs)
				data=$data","$value
			done < raw_data.tmp
			echo $data >> $FILE_NAME
			
			count=$((count+1))
			show_progress $count $TOTAL_COUNT $ptime
		done
	done
done

echo ""
echo "Noxim simulations took $(( $(date +%s) - start )) seconds."
echo ""
echo "Plotting results with python."
python3 plot_noxim_data.py --file $FILE_NAME > /dev/null 2>&1
