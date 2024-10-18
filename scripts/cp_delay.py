#!/usr/bin/env python3
'''check control plane establishment delay'''

import subprocess

for dataplane in ['f5gc', 'srv6']:
    for i in range(1, 11):
        with open(f'build/results/cp-delay-{dataplane}-{i}.txt', 'w', encoding='utf-8') as f:
            subprocess.run(['tshark', '-r',
                            f'build/results/cp-delay-{dataplane}-{i}.pcapng',
                            '-Y', 'ngap'
                            ],
                           check=True,
                           stdout=f,
                           stderr=subprocess.DEVNULL
                           )
mes_t1 = []
mes_t2 = []
for dataplane in ['f5gc', 'srv6']:
    for i in range(1, 11):
        with open(f'build/results/cp-delay-{dataplane}-{i}.txt', 'r', encoding='utf-8') as f:
            for j, line in enumerate(f):
                if 'InitialUEMessage' in line:
                    mes_t1.append(float(line.strip().split(' ')[1]))
                elif 'PDUSessionResourceSetupResponse' in line:
                    mes_t2.append(float(line.strip().split(' ')[1]))
if len(mes_t1) != 20 or len(mes_t2) != 20:
    print('Wrong number of timestamps!')
    print('t1', len(mes_t1))
    print('t2', len(mes_t2))
for i in range(10):
    print(f'% f5gc - {i+1}: {(mes_t2[i] - mes_t1[i])*1000} ms')
for i in range(10):
    print(f'% srv6 - {i+1}: {(mes_t2[10+i] - mes_t1[10+i])*1000} ms')
