#!/usr/bin/env python3
'''check control plane establishment delay'''

from os import path
import subprocess
import sys
import matplotlib.pyplot as plt

class ArgumentError(Exception):
    '''Missing argument'''
class DataError(Exception):
    '''Issue with data'''

if len(sys.argv) != 3:
    raise ArgumentError('Help: ./cp_delay.py iteration results-dir')


MAX = int(sys.argv[1])
DIR = sys.argv[2]

for dataplane in ['f5gc', 'srv6']:
    for i in range(1, MAX+1):
        with open(path.join(DIR, f'cp-delay-{dataplane}-{i}.txt'), 'w', encoding='utf-8') as f:
            subprocess.run(['tshark', '-r',
                            path.join(DIR, f'cp-delay-{dataplane}-{i}.pcapng'),
                            '-Y', 'ngap'
                            ],
                           check=True,
                           stdout=f,
                           stderr=subprocess.DEVNULL
                           )
data = []
for data_i, dataplane in enumerate(['f5gc', 'srv6']):
    data.append([])
    for i in range(1, MAX+1):
        with open(path.join(DIR, f'cp-delay-{dataplane}-{i}.txt'), 'r', encoding='utf-8') as f:
            tmp = []
            for j, line in enumerate(f):
                if 'InitialUEMessage' in line:
                    tmp.append(float(line.strip().split(' ')[1]))
                elif 'PDUSessionResourceSetupResponse' in line:
                    tmp.append(float(line.strip().split(' ')[1]))
            if len(tmp) != 2:
                raise DataError(f'{dataplane}-{i}: too many messages')
            data[data_i].append((tmp[1] - tmp[0])*1000)


print(data)
fig, ax = plt.subplots()
ax.boxplot(data, labels=['UL-CL', 'SR4MEC'],patch_artist=True, boxprops={'facecolor': 'bisque'})
ax.set_ylabel('Time (ms)')
ax.autoscale_view()
plt.title('Comparison of PDU Session Establishment time')
#plt.show()
plt.savefig(path.join(DIR, 'cp-delay.pdf'))
