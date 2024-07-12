#!/usr/bin/env python3
'''Customization for jinja'''
# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT
from __future__ import annotations
import functools
import json
import os.path
import secrets
import shutil
import subprocess
import sys
import typing
import jinja2
import yaml

class TemplateError(Exception):
    '''Template error'''

class GenerationError(Exception):
    '''Generation error'''

class ArgumentError(Exception):
    '''Issue with j2cli arguments'''

class SkipException(Exception):
    '''Skip Exception'''

class _Context:
    _context = {}

    @classmethod
    def alter_context(cls, context: dict) -> dict:
        '''Overrides alter_context'''
        cls._context.update(context)
        return context

    @property
    def dict(self) -> dict:
        '''Get dict'''
        return dict(self._context)

def alter_context(context: dict) -> dict:
    '''Overrides alter_context'''
    return _Context.alter_context(context)

class _Storage:
    def __init__(self):
        self._items = {}

    def set(self, func):
        '''Add (or replace) function into storage'''
        self._items[func.__name__] = func

    @property
    def dict(self) -> dict:
        '''Get dict'''
        return dict(self._items)

class _JinjaDecorator:
    '''Jinja decorator'''
    def __init_subclass__(cls):
        cls._storage = _Storage()

    def __init__(self, *args, **kwargs):
        self.output = 'str'
        self._context = _Context()
        if args and callable(args[0]):
            self.func = args[0]
            self._storage.set(self)
        elif 'output' in kwargs:
            self.output = kwargs['output']

    @property
    def __name__(self) -> str:
        return self.func.__name__

    def __call__(self, *args, **kwargs):
        if args and callable(args[0]):
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
        if '_context' in kwargs:
            # a context is already provided, we don't need to add ours
            return self.func(*args, **kwargs)
        try:
            if '_context' in self.func.__code__.co_varnames:
                max_args = self.func.__code__.co_varnames.index("_context")
                if len(args) > max_args:
                    raise TypeError(
                            f'{self.func.__name__} takes {max_args} '
                            + 'positional arguments (`_context` should not be passed as '
                            + f'positional argument) but {len(args)} were given')
                return self.func(*args, _context=self._context, **kwargs)
        except AttributeError:
            pass
        try:
            if '_context' in self.func.__wrapped__.__code__.co_varnames:
                max_args = self.func.__wrapped__.__code__.co_varnames.index('_context')
                if len(args) > max_args:
                    raise TypeError(
                            f'{self.func.__name__} takes {max_args} '
                            + 'positional arguments (`_context` should not be passed as '
                            + f'positional argument) but {len(args)} were given')
                return self.func(*args, _context=self._context, **kwargs)
        except AttributeError:
            pass
        return self.func(*args, **kwargs)

class J2Filter(_JinjaDecorator): # pylint: disable=too-few-public-methods
    '''Decorator to create filters'''

    @classmethod
    def extra_filters(cls) -> dict:
        '''Overrides extra_filters'''
        return cls._storage.dict

def extra_filters() -> dict:
    '''Overrides extra_filters'''
    return J2Filter.extra_filters()


j2_filter = J2Filter # pylint: disable=invalid-name



class J2Function(_JinjaDecorator): # pylint: disable=too-few-public-methods
    '''Decorator to create functions'''

    @classmethod
    def j2_environment(cls, env):
        '''Override j2_environment'''
        env.globals.update(**cls._storage.dict)
        return env

def j2_environment(env):
    '''Override j2_environment'''
    return J2Function.j2_environment(env)

j2_function = J2Function # pylint: disable=invalid-name

def j2_environment_params():
    '''Extra parameters for the Jinja2 environment'''
    return {
            'trim_blocks': True,
            'lstrip_blocks': True,
            'line_statement_prefix': '#~',
            'keep_trailing_newline': True,
            }

@j2_filter
def indent(text: str, width: typing.Union[int, str] = 1,
           first: bool = False, blank: bool = False) -> str:
    '''Replace default indent function with sane default values'''
    return jinja2.filters.do_indent(s=text, width=width*2, first=first, blank=blank)


class _Dumper(yaml.Dumper): # pylint: disable=too-many-ancestors
    '''Indent yaml list correctly'''
    def increase_indent(self, flow=False, indentless=None): # pylint: disable=unused-argument
        '''Force indentless = False, default to flow=False'''
        return super().increase_indent(flow=flow, indentless=False)

@j2_filter
def json_to_yaml(json_text: str) -> str:
    '''Convert json to yaml'''
    args = json.loads(json_text)
    return yaml.dump(args, sort_keys=False, default_flow_style=False, Dumper=_Dumper).rstrip()

@j2_filter
def s(json_str: str) -> str: # pylint: disable=invalid-name
    '''Convert json to indented yaml'''
    return indent(json_to_yaml(json_str))

@j2_filter
def comment(text: str) -> str:
    '''Comment lines'''
    out = '#' + text
    out = '\n#'.join(out.splitlines())
    return out


@functools.cache # parsing is only required once
def build_and_template_dir():
    '''Get build directory and template directory'''
    pos = None
    for i, j in enumerate(sys.argv[1:]):
        if j == '-o':
            pos = i + 1
            break
    if pos is None:
        raise ArgumentError(
                '`outfile` (`-o`) option is mandatory with functions used by this template.')
    try:
        build, template = sys.argv[1+pos], sys.argv[1+pos+1]
        return os.path.dirname(build), os.path.dirname(template)
    except Exception as exc:
        raise (ArgumentError(
                'Error while parsing j2cli options to find the outfile and template file.')
               ) from exc

@j2_function
@functools.cache # we don't want to copy more than once
def volume_ro(src: str, dst: str) -> str:
    '''Create a read only volume'''
    build, template = build_and_template_dir()
    build, template = os.path.join(build, src), os.path.join(template, src)
    print(f'Copying {template} into {build}.')
    os.makedirs(os.path.dirname(build), exist_ok=True)
    shutil.copy2(src=template, dst=build)
    return f'- ./{src}:{dst}:ro'

@j2_function
def secret(name: str) -> str:
    '''Create a new secret'''
    build, _ = build_and_template_dir()
    build = os.path.join(build, 'secrets', name)
    os.makedirs(os.path.dirname(build), exist_ok=True)
    try:
        with open(build, 'x', encoding='utf-8') as file:
            print(f'Creating new secret `{name}`')
            file.write(secrets.token_hex(16))
    except FileExistsError:
        pass
    return f'{os.path.join("./secrets", name)}'

@j2_function(output='json')
def openssl(host: str, subnet: str, _context: _Context) -> str:
    '''Generate openssl key and pem and return text to create secret'''
    ip_addr = ipv4(host, subnet, _context=_context)
    build, _ = build_and_template_dir()
    key_filename = f'{host}_{subnet}.key'
    pem_filename = f'{host}_{subnet}.pem'
    path_key = os.path.join(build, 'secrets', key_filename)
    path_pem = os.path.join(build, 'secrets', pem_filename)
    if not (os.path.isfile(path_key) and os.path.isfile(path_key)):
        os.makedirs(os.path.join('build', 'secrets'), exist_ok=True)
        print(f'Creating new openssl key and certificate for `{host}.{subnet}`… ', end='')
        try:
            if ("disable_openssl_generation" in _context.dict) and (
                _context.dict["disable_openssl_generation"]):
                raise SkipException
            subprocess.run(['openssl', 'req', '-x509',
                             '-sha256', '-nodes',
                             '-days', '30',
                             '-subj', f'/CN={host}.{subnet}',
                             '-addext', f'subjectAltName=DNS:{host}.{subnet},IP.1:{ip_addr}',
                             '-newkey', 'rsa:2048',
                             '-keyout', path_key,
                             '-out', path_pem
                             ],
                           check=True,
                           stdout=subprocess.DEVNULL,
                           stderr=subprocess.DEVNULL
                        )
        except subprocess.CalledProcessError as exc:
            print("Failed.")
            raise(GenerationError(
                f'Could not create openssl key and certificate for {host}.{subnet}')) from exc
        except SkipException:
            print("Skipped.")
        else:
            print("Done.")

    ret = {
            f'openssl_{host}_{subnet}_key': {
                'file': os.path.join("./secrets", key_filename),
            },
            f'openssl_{host}_{subnet}_pem': {
                'file': os.path.join("./secrets", pem_filename),
            },
    }
    return json.dumps(ret)

@j2_function(output='json')
def openssl_secrets(host: str, subnet: str) -> str:
    '''Mount openssl secrets in the container'''
    return json.dumps([f'openssl_{host}_{subnet}_key', f'openssl_{host}_{subnet}_pem'])

@j2_function(output='json')
def openssl_secrets_pem(host: str, subnet: str) -> str:
    '''Mont openssl pem secret in the container'''
    return json.dumps([f'openssl_{host}_{subnet}_pem'])

@j2_function
def openssl_secret_key(host: str, subnet: str) -> str:
    '''Key file path mounted inside container'''
    return f'/run/secrets/openssl_{host}_{subnet}_key'

@j2_function
def openssl_secret_pem(host: str, subnet: str) -> str:
    '''Pem file path mounted inside container'''
    return f'/run/secrets/openssl_{host}_{subnet}_pem'

@j2_function
def ipv4(host: str, subnet: str, _context: _Context) -> str:
    '''Get IPv4 Address'''
    try:
        addr = _context.dict['subnets'][subnet][host]['ipv4_address']
    except KeyError as exc:
        raise(TemplateError(f'Unknown ipv4 address for {host}.{subnet}')) from exc
    return addr

@j2_function
def ipv6(host: str, subnet: str, _context: _Context) -> str:
    '''Get IPv6 Address'''
    try:
        addr = _context.dict['subnets'][subnet][host]['ipv6_address']
    except KeyError as exc:
        raise(TemplateError(f'Unknown ipv6 address for {host}.{subnet}')) from exc
    return addr

@j2_function
def ipv4_subnet(subnet: str, _context: _Context) -> str:
    '''Get IPv4 subnet'''
    try:
        addr = _context.dict['subnets'][subnet]['subnet']['ipv4_address']
    except KeyError as exc:
        raise(TemplateError(f'Unknown ipv4 subnet: {subnet}')) from exc
    return addr

@j2_function
def ipv6_subnet(subnet: str, _context: _Context) -> str:
    '''Get IPv6 subnet'''
    try:
        addr = _context.dict['subnets'][subnet]['subnet']['ipv6_address']
    except KeyError as exc:
        raise(TemplateError(f'Unknown ipv6 subnet: {subnet}')) from exc
    return addr

@j2_function
def ipv6_prefix(name: str, subnet: str, _context: _Context) -> str:
    '''Get IPv6 prefix'''
    try:
        addr = _context.dict['subnets'][subnet][name]['ipv6_prefix']
    except KeyError as exc:
        raise(TemplateError(f'Unknown ipv6 prefix for subnet {subnet}')) from exc
    return addr

@j2_function(output='json')
def container(name: str, image: str, enable_ipv6: typing.Optional[bool] = False, # pylint: disable=too-many-arguments
              srv6: typing.Optional[bool] = False, iface_tun: typing.Optional[bool] = False,
              command: typing.Optional[str|bool] = None, init: typing.Optional[bool] = False,
              cap_net_admin: typing.Optional[bool] = False, restart: typing.Optional[str] = None,
              debug: typing.Optional[bool] = False) -> str:
    '''Add a container'''
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
    if enable_ipv6:
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
    if init:
        containers[name]['init'] = True
    return json.dumps(containers)

@j2_function(output='json')
def container_setup(name: str) -> str:
    '''Add a setup container'''
    containers = {}
    containers[f'{name}-setup'] = {
        "container_name": f'{name}-setup',
        "network_mode": f'service:{name}',
        "image": 'louisroyer/docker-setup',
        "cap_add": ['NET_ADMIN',],
        "restart": "no",
    }
    return json.dumps(containers)
