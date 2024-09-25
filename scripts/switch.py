#!/usr/bin/env python3
'''Switch UE edge'''
# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT
import argparse
import ipaddress
import requests
import yaml

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='switch',
            description='Switch UE edge'
        )
    parser.add_argument('config')
    parser.add_argument('ue_addr')
    args = parser.parse_args()
    with open(args.config, 'r', encoding='utf-8') as f:
        c = yaml.safe_load(f)
        srgw = f'http://[{c["subnets"]["control"]["srgw0"]["ipv6_address"]}]:8080'
        r = requests.get(f'{srgw}/rules', timeout=1)
        rules = [None, None]
        for ruleid, rule in r.json().items():
            if ipaddress.ip_address(args.ue_addr) in ipaddress.ip_network(
                    rule['Match']['ue-ip-prefix']):
                if not rule['Enabled']:
                    rules[0] = ruleid
                else:
                    rules[1] = ruleid
        if (rules[0] is None) or (rules[1] is None):
            raise ValueError('Could not found 1 enabled and 1 disabled rule for this IP Address')
        requests.patch(f'{srgw}/rules/switch/{rules[0]}/{rules[1]}', timeout=1)
