#!/usr/bin/env python3
# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT
import yaml
import json
import jinja2
import typing
import sys
import os.path
import functools
import shutil

class _Context:
    _context = {}

    global alter_context
    @staticmethod
    def alter_context(c: dict, __context=_context) -> dict:
        '''Overrides alter_context'''
        __context.update(c)
        return c

    @property
    def dict(self) -> dict:
        return dict(self._context)

class _Storage:
    def __init__(self):
        self._items = {}

    def set(self, f):
        '''Add (or replace) function into storage'''
        self._items[f.__name__] = f

    @property
    def dict(self) -> dict:
        return dict(self._items)

class _JinjaDecorator:
    '''Jinja decorator'''
    def __init__(self, *args, **kwargs):
        self.output = 'str'
        self._context = _Context()
        if len(args) and callable(args[0]):
            self.func = args[0]
            self._storage.set(self)
        elif 'output' in kwargs.keys():
            self.output = kwargs['output']

    @property
    def __name__(self) -> str:
        return self.func.__name__

    def __call__(self, *args, **kwargs):
        if len(args) and callable(args[0]):
            self.func = args[0]
            self._storage.set(self)
            if self.output == 'json':
                def with_s(*args, **kwargs):
                    return s(self._call_with_context(*args, **kwargs))
                with_s.__name__ = f'{self.__name__}_s'
                self._storage.set(with_s)
            return self._call_with_context
        return self._call_with_context(*args, **kwargs)

    def _call_with_context(self, *args, **kwargs):
        try:
            if 'context' in self.func.__code__.co_varnames:
                return self.func(*args, context=self._context, **kwargs)
        except AttributeError:
            pass
        try:
            if 'context' in self.func.__wrapped__.__code__.co_varnames:
                return self.func(*args, context=self._context, **kwargs)
        except AttributeError:
            pass
        return self.func(*args, **kwargs)

class filter(_JinjaDecorator):
    '''Decorator to create filters'''
    _storage = _Storage()

    global extra_filters
    @staticmethod
    def extra_filters(__storage=_storage) -> dict:
        '''Overrides extra_filters'''
        return __storage.dict


class function(_JinjaDecorator):
    '''Decorator to create functions'''
    _storage = _Storage()

    global j2_environment
    @staticmethod
    def j2_environment(env, __storage=_storage):
        env.globals.update(**__storage.dict)
        return env

def j2_environment_params():
    '''Extra parameters for the Jinja2 environment'''
    return dict(
            trim_blocks=True,
            lstrip_blocks=True,
            line_statement_prefix='#~',
            keep_trailing_newline=True,
        )

@filter
def indent(s: str, width: typing.Union[int, str] = 2, first: bool = False, blank: bool = False) -> str:
    '''Replace default indent function with sane default values'''
    return jinja2.filters.do_indent(s=s, width=width, first=first, blank=blank)

class _Dumper(yaml.Dumper):
    '''Indent yaml list correctly'''
    def increase_indent(self, flow=False, *args, **kwargs):
        return super().increase_indent(flow=flow, indentless=False)

@filter
def json_to_yaml(s: str) -> str:
    args = json.loads(s)
    return yaml.dump(args, sort_keys=False, default_flow_style=False, Dumper=_Dumper).rstrip()

@filter
def s(s: str) -> str:
    '''Convert json to indented yaml'''
    return indent(json_to_yaml(s))

@functools.cache # parsing is only required once
def build_and_template_dir():
    pos = None
    for i, j in enumerate(sys.argv[1:]):
        if j == '-o':
            pos = i + 1
            break
    if pos is None:
        raise Exception('`outfile` (`-o`) option is mandatory with functions used by this template.')
        return (None, None)
    try:
        build, template = sys.argv[1+pos], sys.argv[1+pos+1]
        return os.path.dirname(build), os.path.dirname(template)
    except:
        raise Exception('Error while parsing j2cli options to find the outfile and template file.')

@function
@functools.cache # we don't want to copy more than once
def volume_ro(s: str, s2: str) -> str:
    build, template = build_and_template_dir()
    build, template = os.path.join(build, s), os.path.join(template, s)
    print(f'Copying {template} into {build}.')
    os.makedirs(os.path.dirname(build), exist_ok=True)
    shutil.copy2(src=template, dst=build)
    return f'- ./{template}:{s2}:ro'

@function
def ipv4(host: str, subnet: str, context: _Context) -> str:
    try:
        addr = context.dict['subnets'][subnet][host]['ipv4_address']
    except:
        raise('Unknown ip address')
    return addr

@function
def ipv6(host: str, subnet: str, context: _Context) -> str:
    try:
       addr = context.dict['subnets'][subnet][host]['ipv6_address']
    except:
        raise('Unknown ip address')
    return addr

@function
def ipv4_subnet(subnet: str, context: _Context) -> str:
    try:
        addr = context.dict['subnets'][subnet]['subnet']['ipv4_address']
    except:
        raise('Unknown ip subnet')
    return addr

@function
def ipv6_subnet(subnet: str, context: _Context) -> str:
    try:
       addr = context.dict['subnets'][subnet]['subnet']['ipv6_address']
    except:
        raise('Unknown ip subnet')
    return addr

@function(output='json')
def container(name: str, image: str, ipv6: typing.Optional[bool] = False, srv6: typing.Optional[bool] = False, iface_tun: typing.Optional[bool] = False,
              command: typing.Optional[str|bool] = None,
              cap_net_admin: typing.Optional[bool] = False, restart: typing.Optional[str] = None, debug: typing.Optional[bool] = False) -> str:
    containers = {}
    if debug:
        containers[f'{name}-debug'] = {
            "container_name": f'{name}-debug',
            "network_mode": f'service:{name}',
            "image": 'louisroyer/network-debug',
            "cap_add": ['NET_ADMIN',],
            "profiles": ['debug',],
        }
    containers[name] = {
        "container_name": name,
        "hostname": name,
        "image": image,
    }
    if command:
        containers[name]['command'] = command
    elif command is None:
        containers[name]['command'] = [' ']
    if restart is not None:
        containers[name]['restart'] = restart
    if ipv6:
        containers[name]['sysctls'] = {
            'net.ipv6.conf.all.disable_ipv6': 0,
        }
    if srv6:
        containers[name]['sysctls'] = {
            'net.ipv6.conf.all.disable_ipv6': 0,
            'net.ipv4.ip_forward': 1,
            'net.ipv6.conf.all.forwarding': 1,
            'net.ipv6.conf.all.seg6_enabled': 1,
            'net.ipv6.conf.default.seg6_enabled': 1,
        }
    if cap_net_admin or srv6:
        containers[name]['cap_add'] = ["NET_ADMIN"]
    if iface_tun or srv6:
        containers[name]['devices'] = ["/dev/net/tun:/dev/net/tun"]
    return json.dumps(containers)

@function(output='json')
def container_setup(name: str) -> str:
    containers = {}
    containers[f'{name}-setup'] = {
        "container_name": f'{name}-setup',
        "network_mode": f'service:{name}',
        "image": 'louisroyer/docker-setup',
        "cap_add": ['NET_ADMIN',],
        "restart": "no",
    }
    return json.dumps(containers)
