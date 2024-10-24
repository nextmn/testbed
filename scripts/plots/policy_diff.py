#!/usr/bin/env python3
'''Create plot for policy diff scenario'''
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
    with open(arguments.slicea, 'r', encoding='utf8') as ping:
        res.append({'tsp': [], 'pqt': []})
        for i, line in enumerate(ping):
            if 'time=' in line:
                res[0]['tsp'].append(float  (line.split('[')[1].split('] ')[0]))
                res[0]['pqt'].append(float(line.split('time='    )[1].split(' ms'  )[0]))
    with open(arguments.sliceb, 'r', encoding='utf8') as ping:
        res.append({'tsp': [], 'pqt': []})
        for i, line in enumerate(ping):
            if 'time=' in line:
                res[1]['tsp'].append(float  (line.split('[')[1].split('] ')[0]))
                res[1]['pqt'].append(float(line.split('time='    )[1].split(' ms'  )[0]))
    first = min(res[0]['tsp'][0], res[1]['tsp'][0])
    for i, timestamp in enumerate(res[0]['tsp']):
        res[0]['tsp'][i] = timestamp - first
    for i, timestamp in enumerate(res[1]['tsp']):
        res[1]['tsp'][i] = timestamp - first
    _, axplt = plt.subplots()
    axplt.set_xlabel('Time (s)')
    axplt.set_ylabel('RTT (ms)')
    axplt.plot(res[0]['tsp'], res[0]['pqt'], color='tab:red', label='Slice A')
    axplt.plot(res[1]['tsp'], res[1]['pqt'], color='tab:blue', label='Slice B')
    axplt.autoscale_view()
    axplt.legend()
    plt.savefig(arguments.output)
    print(f'plot saved in {arguments.output}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='policy_diff',
            description='Convert ping result into plot'
        )
    parser.set_defaults(func=plot)
    parser.add_argument('slicea', type=pathlib.Path,
            help='ping result file')
    parser.add_argument('sliceb', type=pathlib.Path,
            help='ping result file')
    parser.add_argument('output', type=pathlib.Path,
            help='output file')

    args = parser.parse_args()
    args.func(args)
