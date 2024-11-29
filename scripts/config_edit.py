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

class Dumper(yaml.Dumper): #pylint: disable=too-many-ancestors
    '''yaml dumper'''
    def increase_indent(self, flow=False, indentless=False):
        return super().increase_indent(flow, False)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='config-edit',
            description='edit configuration'
        )
    parser.add_argument('buildconfig')
    parser.add_argument('--dataplane')
    parser.add_argument('--controlplane')
    parser.add_argument('--nb-ue')
    parser.add_argument('--nb-edges')
    parser.add_argument('--log-level')
    parser.add_argument('--full-debug')
    parser.add_argument('--ran')
    parser.add_argument('--handover')
    args = parser.parse_args()
    ran = ('stable', 'dev')
    controlplane = ('free5gc', 'nextmn-lite')
    dataplane = ('free5gc', 'nextmn-upf', 'nextmn-srv6')
    log_levels = ('trace', 'debug', 'info', 'warning', 'error', 'fatal', 'panic')
    try:
        if args.dataplane:
            dp = args.dataplane.split('+')
            for d in dp:
                if d not in dataplane:
                    raise ConfigException(
                         f'Invalid dataplane value: use values from {dataplane} (separated by `+`)')
        if args.nb_ue and (int(args.nb_ue) > 2 or int(args.nb_ue) < 1):
            raise ConfigException('Too many UEs: use 1 or 2')
        if args.nb_edges and (int(args.nb_edges) > 2 or int(args.nb_edges) < 1):
            raise ConfigException('Too many edges: use 1 or 2')
        if args.log_level and (args.log_level not in log_levels):
            raise ConfigException(f'Invalid log level: use one from {log_levels}')
        if args.full_debug and (args.full_debug.lower() not in ('true', 'false')):
            raise ConfigException('Invalid value for full debug: must be a boolean')
        if args.handover and (args.handover.lower() not in ('true', 'false')):
            raise ConfigException('Invalid value for handover: must be a boolean')
        if args.ran and (args.ran not in ran):
            raise ConfigException(f'Invalid ran config: use one from {ran}')
        if args.controlplane and (args.controlplane not in controlplane):
            raise ConfigException(f'Invalid controlplane config: use one from {controlplane}')
    except ConfigException as e:
        print(f'Error: {e}', file=sys.stderr)
        sys.exit(1)

    with open(args.buildconfig, "r", encoding='utf-8') as f:
        c = yaml.safe_load(f)
        if args.dataplane:
            dp = args.dataplane.split('+')
            c['config']['topology']['dataplane'] = dp
        if args.controlplane:
            c['config']['topology']['controlplane'] = args.controlplane
        if args.nb_ue:
            c['config']['topology']['nb_ue'] = int(args.nb_ue)
        if args.nb_edges:
            c['config']['topology']['nb_edges'] = int(args.nb_edges)
        if args.log_level:
            c['config']['topology']['log_level'] = args.log_level
        if args.full_debug is not None:
            c['config']['topology']['full_debug'] = args.full_debug.lower() == 'true'
        if args.handover is not None:
            c['config']['topology']['ran']['handover'] = args.handover.lower() == 'true'
        if args.ran:
            c['config']['topology']['ran']['version'] = args.ran
        with open(args.buildconfig, 'w', encoding='utf-8') as f2:
            yaml.dump(c, f2, Dumper, default_flow_style=False)
