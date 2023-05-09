import argparse
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

parser = argparse.ArgumentParser(description='Plot noxim output data. If multiple lines have the same route and pir they will be averaged')
parser.add_argument('-f', '--file', required=True, help='CSV file with noxim output data', action='store')
args = parser.parse_args()
print(args)
if __name__ == '__main__':
    df = pd.read_csv(args.file)
    routes = df['route'].unique()
    pirs = df['pir'].unique()
    
    plt.subplot(1,2,1)
    for route in routes:
        delay_pir = df.loc[df['route'] == route, ['global_avg_delay_cycles', 'pir']]
        delay = []
        #  Average values that have the same route and pir
        for pir in pirs:
            delays = delay_pir.loc[delay_pir['pir'] == pir, 'global_avg_delay_cycles'].to_numpy()
            delay.append(np.mean(delays))
        plt.plot(pirs, delay, label=route.replace('_', ' ').lower())
    plt.grid()
    plt.legend(title='Routing Technique:')
    plt.xlabel('Packet injection rate (flit/cycle/tile)')
    plt.ylabel('Average delay (cycle)')
    plt.title('Delay')

    plt.subplot(1,2,2)
    for route in routes:
        ipt_pir = df.loc[df['route'] == route, ['avg_ip_throuput', 'pir']]

        ipt = []
        for pir in pirs:
            ipts = ipt_pir.loc[ipt_pir['pir'] == pir, 'avg_ip_throuput'].to_numpy()
            ipt.append(np.mean(ipts))
        plt.plot(pirs, ipt, label=route.replace('_', ' ').lower())
    plt.grid()
    plt.legend(title='Routing Technique:')
    plt.xlabel('Packet injection rate (flit/cycle/tile)')
    plt.ylabel('Average IP throughput (flit/cycle/tile)')
    plt.title('Packet Throughput')
    # plt.tight_layout()
    plt.show()