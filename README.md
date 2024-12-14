# Testbed
![CI](https://github.com/nextmn/testbed/actions/workflows/main.yml/badge.svg)

## Getting started
### Dependencies
This testbed has been developped using Debian 12 (Bookworm), but it should also work on all other Linux distributions supported by Docker as long as a Linux kernel is used on the host system (incompatible with Microsoft WSL).

The following Debian's packages are required (or their equivalent on your distribution):
- [`docker-ce`](https://docs.docker.com/engine/install/debian/#install-using-the-repository)
- [`docker-compose-plugin`](https://docs.docker.com/compose/install/linux/#install-using-the-repository)
- `python3`
- `python3-yaml`
- `j2cli`
- `make`
- `acl`
- `openssl`
- `python3-matplotlib`

>[!NOTE]
> If you intend to use Free5GC’s UPF (with `make set/dataplane/free5gc`),
> install [Free5CG's GTP5G kernel module](https://github.com/free5gc/gtp5g) on your host.
> Please note that you need to have Linux headers installed on the host to be able to install the module
> (for example, the package `linux-headers-amd64` on Debian if you are on an amd64 architecture).

### Usage
> [!IMPORTANT]
> Make sure to enable IPv6.
This can be done by adding the following in `/etc/docker/daemon.json`:
 ```json
{
	"ipv6": true,
	"fixed-cidr-v6": "fdd4:95c2:f557::/64",
}
```

```text
make build # build
make pull # update docker images
make up # run containers
make down # stop containers
```

The Makefile provides some other commands you might want to use. They are described in [`doc/Commands.md`](https://github.com/nextmn/testbed/wiki/Commands)

#### Configuration
Configuration is done in the file [`default-config.yaml`](./default-config.yaml). Currently, it only contains a list of IP addresses.

#### Documentation
Documentation is available in the [`doc`](./doc) directory.

![edge intance access through SRv6](./img/edge-instance-access-through-srv6.svg)

### Contributing
#### Syntax coloration
To enable syntax coloration in Vim, you can use the following plugin: [`nextmn/vim-yaml-jinja`](https://github.com/nextmn/vim-yaml-jinja).

#### PCAP analysis
To analyse RAN traffic, you can install the following Wireshark/Tshark plugin : [`nextmn/RLS-wireshark-dissector`](https://github.com/nextmn/RLS-wireshark-dissector).

### Known issues
- Docker version `5:25.0.0` has [a bug](https://github.com/moby/moby/issues/47120) that prevent running the testbed. Use a different version (`5:25.0.1` or higher, or `5:24.*` or lower).
- To be able to use Free5GC's UPFs along with NextMN-Lite (`make set/dataplane/free5gc && make set/controlplane/nextmn-lite`), you must apply the patch provided in [free5gc/gtp5g#130](https://github.com/free5gc/gtp5g/pull/130) (or you may try to disable GTP Sequence Numbers). If you don't, downlink packets wil be malformed, and thus dropped by NextMN's gNB Lite.

## Copyright
### Author
Louis Royer

### License
The testbed code in this repository is under the MIT license, but the various software used, which are distributed in particular in the form of Docker images, are under other licenses.
Notably:
- [UERANSIM](https://github.com/aligungr/UERANSIM) is under the GPL-3.0 license
- [Free5GC](https://github.com/free5gc) is under the Apache-2.0 license
- Debian packaged softwares are under various free licenses available at `/usr/share/doc/*/copyright` into Docker images.
