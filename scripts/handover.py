#!/usr/bin/env python3
'''Perform handover'''
# Copyright Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT
import argparse
import requests
import yaml

def area(gnb: str) -> str:
    '''Get the name of gnb's Area '''
    # TODO: this should not be hardcoded
    area1 = ('gnbl1', 'gnbl2')
    area2 = ('gnbl3',)
    if gnb in area1:
        return 'area1'
    if gnb in area2:
        return 'area2'
    raise ValueError("Unknown Area for gnb")


def same_area(gnb1: str, gnb2: str) -> bool:
    '''Compare Areas of gnbs'''
    area1, area2 = area(gnb1), area(gnb2)
    return area1 == area2

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
            prog='handover',
            description='Perform handover'
        )
    parser.add_argument('config', help='testbed configuration file, e.g. `build/config.yaml`')
    parser.add_argument('ue', help='ue container, e.g. `uel1`')
    parser.add_argument('dnn', help='dnn of the pdu session, e.g. `srv6`')
    parser.add_argument('gnb_target', help='target gnb container, e.g. `gnbl3`')
    parser.add_argument('gnb_source', help='source gnb container, e.g. `gnbl1`')
    args = parser.parse_args()

    # TODO: this should not be hardcoded
    if args.dnn == "srv6":
        UE_ADDR  = "10.2.0.1"
    elif args.dnn == "free5gc":
        UE_ADDR = "10.2.1.1"
    elif args.dnn == "nextmn-upf":
        UE_ADDR = "10.2.2.1"
    else:
        raise ValueError("DNN must be in (srv6, free5gc, nextmn-upf)")


    # TODO: this info should be guessable by the gNB
    indirect_forwarding = not same_area(args.gnb_source, args.gnb_target)

    with open(args.config, 'r', encoding='utf-8') as f:
        c = yaml.safe_load(f)
        gnb_source_uri = f'http://[{c["subnets"]["control"][args.gnb_source]["ipv6_address"]}]:8080'
        gnb_target_uri = f'http://[{c["subnets"]["control"][args.gnb_target]["ipv6_address"]}]:8080'
        ue_uri = f'http://[{c["subnets"]["control"][args.ue]["ipv6_address"]}]:8080'
        handover_req = {
                "ue-ctrl": ue_uri,
                "gnb-target": gnb_target_uri,
                "sessions": [{
                    "ue-addr": UE_ADDR,
                    "dnn": args.dnn,
                    }],
                "indirect-forwarding": indirect_forwarding,
                }
        requests.post(f'{gnb_source_uri}/cli/ps/handover', json=handover_req, timeout=1)
