#!/usr/bin/env python3
'''Show control plane rules in web browser'''
# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

import argparse
import webbrowser
import yaml

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='show_rules',
            description='Show control plane rules'
        )
    parser.add_argument('config')
    args = parser.parse_args()
    with open(args.config, 'r', encoding='utf-8') as f:
        c = yaml.safe_load(f)
        # TODO: open all the below without hardcoding list of controllers/routers
        controller = f'http://[{c["subnets"]["control"]["srv6-ctrl"]["ipv6_address"]}]:8080'
        r0 = f'http://[{c["subnets"]["control"]["r0"]["ipv6_address"]}]:8080'
        r1 = f'http://[{c["subnets"]["control"]["r1"]["ipv6_address"]}]:8080'
        r2 = f'http://[{c["subnets"]["control"]["r2"]["ipv6_address"]}]:8080'
        srgw0 = f'http://[{c["subnets"]["control"]["srgw0"]["ipv6_address"]}]:8080'
        srgw1 = f'http://[{c["subnets"]["control"]["srgw1"]["ipv6_address"]}]:8080'
        webbrowser.get('firefox').open_new_tab(f'{controller}/routers#controller')
        webbrowser.get('firefox').open_new_tab(f'{r0}/rules#r0')
        webbrowser.get('firefox').open_new_tab(f'{r1}/rules#r1')
        webbrowser.get('firefox').open_new_tab(f'{r2}/rules#r2')
        webbrowser.get('firefox').open_new_tab(f'{srgw0}/rules#srgw0')
        webbrowser.get('firefox').open_new_tab(f'{srgw1}/rules#srgw1')
