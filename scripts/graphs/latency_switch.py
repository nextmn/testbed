#!/usr/bin/env python3
'''Create plot for latency switch scenario'''
# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

import argparse
import os
import pathlib
import matplotlib.pyplot as plt

def plot(arguments: argparse.Namespace):
    '''Write plot'''
    pqt = []
    tsp = []
    with open(arguments.input, 'r', encoding='utf8') as ping:
        for i, line in enumerate(ping):
            if 'time=' in line:
                tsp.append(float  (line.split('[')[1].split('] ')[0]))
                pqt.append(float(line.split('time='    )[1].split(' ms'  )[0]))
    first = tsp[0]
    for i, timestamp in enumerate(tsp):
        tsp[i] = timestamp - first
    _, axplt = plt.subplots()
    axplt.set_xlabel('Time (s)')
    axplt.set_ylabel('Latency (ms)')
    axplt.plot(tsp, pqt)
    axplt.autoscale_view()
    plt.title('Latency evolution with instance switch')
    plt.savefig(f'{os.path.splitext(arguments.input)[0]}.pdf')
    print(f'plot saved in {os.path.splitext(arguments.input)[0]}.pdf')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='latency_switch',
            description='Convert ping result into plot'
        )
    parser.set_defaults(func=plot)
    parser.add_argument('input', type=pathlib.Path,
            help='ping result file')

    args = parser.parse_args()
    args.func(args)
