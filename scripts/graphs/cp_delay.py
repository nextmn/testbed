#!/usr/bin/env python3
'''Check control plane establishment delay'''
# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

from os import path
import argparse
import os
import pathlib
import subprocess
import matplotlib.pyplot as plt

class DataError(Exception):
    '''Issue with data'''

def convert(arguments: argparse.Namespace):
    '''Convert .pcapng to .pcapng.txt'''
    for file in os.listdir(arguments.dir):
        filename = os.fsdecode(file)
        if filename.endswith('.pcapng'):
            with open(path.join(arguments.dir, f'{filename}.txt'), 'w', encoding='utf-8') as out:
                subprocess.run(['tshark', '-r',
                                path.join(arguments.dir, filename),
                                '-Y', 'ngap'
                                ],
                               check=True,
                               stdout=out,
                               stderr=subprocess.DEVNULL
                               )

def plot(arguments: argparse.Namespace):
    '''Write plot'''
    data = []
    for data_i, dataplane in enumerate(['f5gc', 'srv6']):
        data.append([])
        for i in range(1, arguments.num+1):
            with open(path.join(arguments.dir, f'cp-delay-{dataplane}-{i}.pcapng.txt'),
                      'r', encoding='utf-8') as input_file:
                tmp = []
                for line in input_file:
                    if 'InitialUEMessage' in line:
                        tmp.append(float(line.strip().split(' ')[1]))
                    elif 'PDUSessionResourceSetupResponse' in line:
                        tmp.append(float(line.strip().split(' ')[1]))
                if len(tmp) != 2:
                    print(f'skip {dataplane}-{i}: {len(tmp)} messages instead of 2.')
                    #raise DataError(f'{dataplane}-{i}: too many messages')
                else:
                    if (tmp[1] - tmp[0]) * 1000 > 500:
                        print(f'more than 500ms: {dataplane}-{i}')
                    data[data_i].append((tmp[1] - tmp[0])*1000)
    _, axplt = plt.subplots()
    axplt.boxplot(data, labels=['UL-CL', 'SR4MEC'],
                  patch_artist=True, boxprops={'facecolor': 'bisque'})
    axplt.set_ylabel('Time (ms)')
    axplt.autoscale_view()
    plt.title('Comparison of PDU Session Establishment time')
    plt.savefig(path.join(arguments.dir, 'cp-delay.pdf'))
    print(f'plot saved in {path.join(arguments.dir, "cp-delay.pdf")}')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='cp_delay',
            description='Convert pcap of control plane delay into graph'
        )
    subparser = parser.add_subparsers(required=True)
    parser_text = subparser.add_parser('text',
            help='convert .pcapng files from the directory to .pcapng.txt files')
    parser_text.set_defaults(func=convert)
    parser_text.add_argument('dir', type=pathlib.Path,
            help='directory containing .pcapng files to convert')

    parser_plot = subparser.add_parser('plot', help='write plot from .pcapng.txt files')
    parser_plot.set_defaults(func=plot)
    parser_plot.add_argument('dir', type=pathlib.Path,
            help='directory containing .pcapng.txt files')
    parser_plot.add_argument('num', type=int,
            help='number of .pcapng.txt files to use')

    args = parser.parse_args()
    args.func(args)
