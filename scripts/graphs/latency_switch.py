#!/usr/bin/env python3
'''create plot'''
import sys
import matplotlib.pyplot as plt

class ArgumentError(Exception):
    '''Missing argument'''

if len(sys.argv) != 2:
    raise ArgumentError('Filename missing')

pqt = []
tsp = []
with open(sys.argv[1], 'r', encoding='utf8') as ping:
    for i, line in enumerate(ping):
        if 'time=' in line:
            tsp.append(float  (line.split('[')[1].split('] ')[0]))
            pqt.append(float(line.split('time='    )[1].split(' ms'  )[0]))
first = tsp[0]
for i, timestamp in enumerate(tsp):
    tsp[i] = timestamp - first


fig, ax = plt.subplots()

ax.set_xlabel('Time (s)')
ax.set_ylabel('Latency (ms)')
ax.plot(tsp, pqt)
ax.autoscale_view()
plt.title('Latency evolution with instance switch')
#plt.show()
plt.savefig(f'{sys.argv[1].split(".txt", maxsplit=1)[0]}.pdf')
