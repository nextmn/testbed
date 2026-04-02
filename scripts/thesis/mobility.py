#!/usr/bin/env python3
'''Create plot for mobility scenario'''
# Copyright Louis Royer and the NextMN contributors. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

import argparse
import pathlib
import matplotlib.pyplot as plt
import matplotlib as mpl
from matplotlib.ticker import FuncFormatter

def fmt(value, unused):
    '''formatter'''
    _ = unused
    if str(value).endswith('.0'):
        value = str(value)[:-2]
    return value


def plot(arguments: argparse.Namespace):
    '''Write plot'''
    res = []
    with open(arguments.input, 'r', encoding='utf8') as ping:
        res.append({'tsp': [], 'pqt': []})
        for i, line in enumerate(ping):
            if 'time=' in line:
                res[0]['tsp'].append(float(line.split('[')[1].split('] ')[0]))
                res[0]['pqt'].append(float(line.split('time=')[1].split(' ms')[0]))
    first = res[0]['tsp'][0]
    for i, timestamp in enumerate(res[0]['tsp']):
        res[0]['tsp'][i] = timestamp - first
    mpl.rcParams["font.size"] = 15
    _, axplt = plt.subplots(figsize=(7,4.2))
    axplt.set_xlim(-1, 21)
    axplt.set_ylim(29, 56)
    axplt.set_xlabel('$t$ (s)')
    axplt.set_ylabel('RTT (ms)')
    axplt.plot(res[0]['tsp'], res[0]['pqt'], color='tab:red')
    plt.gca().xaxis.set_major_formatter(FuncFormatter(fmt))
    axplt.autoscale_view()
    plt.tight_layout()
    plt.savefig(arguments.output, bbox_inches='tight')
    print(f'plot saved in {arguments.output}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='mobility',
            description='Convert ping result into plot'
        )
    parser.set_defaults(func=plot)
    parser.add_argument('input', type=pathlib.Path,
            help='ping result file')
    parser.add_argument('output', type=pathlib.Path,
            help='output file')

    args = parser.parse_args()
    args.func(args)
