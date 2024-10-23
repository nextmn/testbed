#!/usr/bin/env python3
'''Editor for testbed configuration'''
# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT
import argparse
import sys
import yaml

class ConfigException(Exception):
    '''Configuration issue'''

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='config-edit',
            description='edit configuration'
        )
    parser.add_argument('buildconfig')
    parser.add_argument('--dataplane')
    parser.add_argument('--nb-ue')
    parser.add_argument('--nb-edges')
    parser.add_argument('--log-level')
    parser.add_argument('--full-debug')
    args = parser.parse_args()
    dataplane = ('free5gc', 'nextmn-upf', 'nextmn-srv6')
    log_levels = ('trace', 'debug', 'info', 'warning', 'error', 'fatal', 'panic')
    try:
        if args.dataplane and args.dataplane not in dataplane:
            raise ConfigException(f'Invalid dataplane value: use one from {dataplane}')
        if args.nb_ue and (int(args.nb_ue) > 2 or int(args.nb_ue) < 1):
            raise ConfigException('Too many UEs: use 1 or 2')
        if args.nb_edges and (int(args.nb_edges) > 2 or int(args.nb_edges) < 1):
            raise ConfigException('Too many edges: use 1 or 2')
        if args.log_level and (args.log_level not in log_levels):
            raise ConfigException(f'Invalid log level: use one from {log_levels}')
        if args.full_debug and (args.full_debug.lower() not in ('true', 'false')):
            raise ConfigException('Invalid value for full debug: must be a boolean')
    except ConfigException as e:
        print(f'Error: {e}', file=sys.stderr)
        sys.exit(1)

    with open(args.buildconfig, "r", encoding='utf-8') as f:
        c = yaml.safe_load(f)
        if args.dataplane:
            c['config']['topology']['dataplane'] = args.dataplane
        if args.nb_ue:
            c['config']['topology']['nb_ue'] = int(args.nb_ue)
        if args.nb_edges:
            c['config']['topology']['nb_edges'] = int(args.nb_edges)
        if args.log_level:
            c['config']['topology']['log_level'] = args.log_level
        if args.full_debug is not None:
            c['config']['topology']['full_debug'] = args.full_debug.lower() == 'true'
        with open(args.buildconfig, 'w', encoding='utf-8') as f2:
            yaml.dump(c, f2)
