# Testbed
![CI](https://github.com/nextmn/testbed/actions/workflows/main.yml/badge.svg)

## Getting started
### Dependencies
This testbed has been developped using Debian 12 (Bookworm), but it should also work on all other Linux distributions supported by Docker as long as a Linux kernel is used on the host system (incompatible with Microsoft WSL).

The following Debian's packets are required (or their equivalent on your distribution):
- [`docker-ce`](https://docs.docker.com/engine/install/debian/#install-using-the-repository)
- [`docker-compose-plugin`](https://docs.docker.com/compose/install/linux/#install-using-the-repository)
- `j2cli`
- `make`

### Usage
```text
make j # build
make pull # update docker images
make u # run containers
make d # stop containers
```

#### Configuration
Configuration is done in the file `config.yaml`. Currently, it only contains a list of IP addresses.

#### Documentation
Documentation is available in the `doc` directory.

![edge intance access through SRv6](./doc/img/edge-instance-access-through-srv6.svg)

### Contributing
#### Syntax coloration
To enable syntax coloration in vim, you can use the following plugin: [`nextmn/vim-yaml-jinja`](https://github.com/nextmn/vim-yaml-jinja).

#### PCAP analysis
To analyse RAN traffic, you can install the following Wireshark/Tshark plugin : [`nextmn/RLS-wireshark-dissector`](https://github.com/nextmn/RLS-wireshark-dissector).

### Known issues
Docker version `5:25.0.0` has [a bug](https://github.com/moby/moby/issues/47120) that prevent running the testbed. Use a different version (`5:25.0.1` or higher, or `5:24.*` or lower).

## Copyright
### Author
Louis Royer

### License
The testbed code in this repository is under the MIT license, but the various software used, which are distributed in particular in the form of Docker images, are under other licenses.
Notably:
- [UERANSIM](https://github.com/aligungr/UERANSIM) is under the GPL-3.0 license
- [Free5GC](https://github.com/free5gc) is under the Apache-2.0 license
- Debian packaged softwares are under various free licenses available at `/usr/share/doc/*/copyright` into Docker images.
