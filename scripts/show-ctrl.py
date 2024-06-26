#!/usr/bin/env python3

import yaml
import argparse
import webbrowser

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='show-rules',
            description='Show control plane rules'
        )
    parser.add_argument('config')
    args = parser.parse_args()
    with open(args.config) as f:
        c = yaml.safe_load(f)
        controller = f'http://[{c["subnets"]["control"]["srv6-ctrl"]["ipv6_address"]}]:8080'
        rr = f'http://[{c["subnets"]["control"]["rr"]["ipv6_address"]}]:8080'
        r0 = f'http://[{c["subnets"]["control"]["r0"]["ipv6_address"]}]:8080'
        r1 = f'http://[{c["subnets"]["control"]["r1"]["ipv6_address"]}]:8080'
        srgw = f'http://[{c["subnets"]["control"]["srgw0"]["ipv6_address"]}]:8080'
        webbrowser.get('firefox').open_new_tab(f'{controller}/routers#controller')
        webbrowser.get('firefox').open_new_tab(f'{rr}/rules#rr')
        webbrowser.get('firefox').open_new_tab(f'{r0}/rules#r0')
        webbrowser.get('firefox').open_new_tab(f'{r1}/rules#r1')
        webbrowser.get('firefox').open_new_tab(f'{srgw}/rules#srgw')
