# Testbed
Warning: __WORK IN PROGRESS__
## Getting started
### Dependencies
- `docker-ce`
- `docker-compose-plugin`
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
TODO: Configuration is done in the file `config.yaml`.

#### Documentation
Documentation is available in the `doc` directory.

### Contributing
#### Syntax coloration
To enable syntax coloration in vim, you can use the following plugin: [`louisroyer/vim-yaml-jinja`](https://github.com/louisroyer/vim-yaml-jinja).

#### PCAP analysis
To analyse RAN traffic, you can install the following Wireshark/Tshark plugin : [`louisroyer/RLS-wireshark-dissector`](https://github.com/louisroyer/RLS-wireshark-dissector).

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
