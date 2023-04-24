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
    for route in routes:
        delay_pir = df.loc[df['route'] == route, ['global_avg_delay_cycles', 'pir']]#.to_numpy()
        delay = []
        #  Average values that have the same route and pir
        for pir in pirs:
            delays = delay_pir.loc[delay_pir['pir'] == pir, 'global_avg_delay_cycles'].to_numpy()
            delay.append(np.mean(delays))
        plt.plot(pirs, delay, label=route)
    plt.legend(title='Routing Technique:')
    plt.xlabel('Packet injection rate (flit/cycle/tile)')
    plt.ylabel('Average delay (cycle)')
    plt.title('Delay vs Locality')
    plt.show()


