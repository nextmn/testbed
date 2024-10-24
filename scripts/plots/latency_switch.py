#!/usr/bin/env python3
'''Create plot for latency switch scenario'''
# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

import argparse
import pathlib
import matplotlib.pyplot as plt

def plot(arguments: argparse.Namespace):
    '''Write plot'''
    res = []
    with open(arguments.inputsr4mec, 'r', encoding='utf8') as ping:
        res.append({'tsp': [], 'pqt': []})
        for i, line in enumerate(ping):
            if 'time=' in line:
                res[0]['tsp'].append(float  (line.split('[')[1].split('] ')[0]))
                res[0]['pqt'].append(float(line.split('time='    )[1].split(' ms'  )[0]))
    with open(arguments.inputulcl, 'r', encoding='utf8') as ping:
        res.append({'tsp': [], 'pqt': []})
        for i, line in enumerate(ping):
            if 'time=' in line:
                res[1]['tsp'].append(float  (line.split('[')[1].split('] ')[0]))
                res[1]['pqt'].append(float(line.split('time='    )[1].split(' ms'  )[0]))
    first = res[0]['tsp'][0]
    for i, timestamp in enumerate(res[0]['tsp']):
        res[0]['tsp'][i] = timestamp - first
    first = res[1]['tsp'][0]
    for i, timestamp in enumerate(res[1]['tsp']):
        res[1]['tsp'][i] = timestamp - first
    _, axplt = plt.subplots()
    axplt.set_xlabel('Time (s)')
    axplt.set_ylabel('RTT (ms)')
    axplt.plot(res[0]['tsp'], res[0]['pqt'], color='tab:blue', label='SR4MEC')
    axplt.plot(res[1]['tsp'], res[1]['pqt'], color='tab:red', label='UL-CL')
    axplt.autoscale_view()
    axplt.legend()
    plt.savefig(arguments.output)
    print(f'plot saved in {arguments.output}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='latency_switch',
            description='Convert ping result into plot'
        )
    parser.set_defaults(func=plot)
    parser.add_argument('inputsr4mec', type=pathlib.Path,
            help='ping result file')
    parser.add_argument('inputulcl', type=pathlib.Path,
            help='ping result file')
    parser.add_argument('output', type=pathlib.Path,
            help='output file')

    args = parser.parse_args()
    args.func(args)
