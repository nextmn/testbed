# Adressing
## Network management
| Entity         | Pool          | Comment                                                                                   |
|----------------|---------------|-------------------------------------------------------------------------------------------|
| docker-compose | `10.1.0.0/16` | Manual allocation.                                                                        |
| docker-compose | `fd00::/8`    | Manual allocation. TODO: RFC4194 allocation.                                              |
| free5gc        | `10.2.0.0/16` | Manual allocation. NB: IPv6 unsupported in RAN.                                           |
| nextmn         | `fc00::/8`    | SR domain. Manual allocation. NB: no RFC4194 allocation because /64 subnets is too short. |
| nextmn         | `10.3.0.0/16` | SR/GTP interworking (N3). Manual allocation in SRGWs.                                     |
| service        | `10.4.0.0/16` | Services network. Each service is allocated an address from this network.                 |



## Subnets
| Name      | Management     | Subnet IPv4   | Subnet IPv6         | Comment                                       |
|-----------|----------------|---------------|---------------------|-----------------------------------------------|
| ran       | docker-compose | `10.1.0.0/24` | `fd00:0:0:0:1::/80` | Virtual RAN for UERANSIM.                     |
| sbi       | docker-compose | `10.1.1.0/24` | disabled            | Control plane: Software Based Interface       |
| db        | docker-compose | `10.1.2.0/24` | disabled            | Control plane: database                       |
| control   | docker-compose | `10.1.3.0/24` | `fd00:0:0:0:2::/80` | (N2 + N4) Management interfaces : NGAP + PFCP |
| dataplane | docker-compose | `10.1.4.0/24` | `fd00:0:0:0:3::/80` | (N3 + N9) Dataplane backbone                  |
| edge      | docker-compose | `10.1.5.0/24` | disabled            | (N6) Edges instances                          |
| nextmndb  | docker-compose | `10.1.6.0/24` | `fd00:0:0:0:4::/80` | Internal databases for NextMN                 |
| slice0    | free5gc        | `10.2.0.0/24` | disabled            | Slice 0                                       |
| slice1    | free5gc        | `10.2.1.0/24` | disabled            | Slice 1                                       |
| srgw0     | nextmn/srgw0   | `10.3.0.1/32` | `fc00:1::/32`       | srgw0 locators                                |
| r0        | nextmn/r0      | disabled      | `fc00:2::/32`       | r0 locator                                    |
| r1        | nextmn/r1      | disabled      | `fc00:3::/32`       | r1 locator                                    |
| rr        | nextmn/rr      | disabled      | `fc00:4::/32`       | rr locator                                    |




## Hosts
> [!IMPORTANT]
> IPv4 addresses ending with `.254` and IPv6 addresses ending with `:8000:0:1` are used by Docker internally (gateway).

| Name       | Image                               | Network   | IPv4 address    | IPv6 address            | Comment                                     |
|------------|-------------------------------------|-----------|-----------------|-------------------------|---------------------------------------------|
| ue1        | `louisroyer/ueransim-ue`            | ran       | auto            | auto                    |                                             |
| ue1        | `louisroyer/ueransim-ue`            | slice0    | `10.2.0.1`      | disabled                |                                             |
| ue2        | `louisroyer/ueransim-ue`            | ran       | auto            | auto                    |                                             |
| ue2        | `louisroyer/ueransim-ue`            | slice0    | `10.2.0.2`      | disabled                |                                             |
| gnb1       | `louisroyer/ueransim-gnb`           | ran       | `10.1.0.129`    | `fd00:0:0:0:1:8000:0:2` |                                             |
| gnb1       | `louisroyer/ueransim-gnb`           | control   | `10.1.3.129`    | auto                    |                                             |
| gnb1       | `louisroyer/ueransim-gnb`           | dataplane | `10.1.4.129`    | auto (not used)         | Route to srgw0                              |
| gnb2       | `louisroyer/ueransim-gnb`           | ran       | `10.1.0.130`    | `fd00:0:0:0:1:8000:0:3` |                                             |
| gnb2       | `louisroyer/ueransim-gnb`           | control   | `10.1.3.130`    | auto                    |                                             |
| gnb2       | `louisroyer/ueransim-gnb`           | dataplane | `10.1.4.130`    | auto (not used)         | Route to srgw0                              |
| srgw0      | `louisroyer/dev-nextmn-srv6`        | control   | `10.1.3.131`    | `fd00:0:0:0:2:8000:0:2` |                                             |
| srgw0      | `louisroyer/dev-nextmn-srv6`        | dataplane | `10.1.4.131`    | `fd00:0:0:0:3:8000:0:2` | IPv6 routes to SR domain (rr)               |
| srgw0      | `louisroyer/dev-nextmn-srv6`        | srgw0     | `10.3.0.1`      | disabled                | H.M.GTP4.D                                  |
| srgw0      | `louisroyer/dev-nextmn-srv6`        | srgw0     | disabled        | `fc00:1:1::/48`         | End.M.GTP4.E                                |
| srgw0      | `louisroyer/dev-nextmn-srv6`        | nextmndb  | auto            | auto                    |                                             |
| r0         | `louisroyer/dev-nextmn-srv6`        | control   | auto            | `fd00:0:0:0:2:8000:0:4` |                                             |
| r0         | `louisroyer/dev-nextmn-srv6`        | dataplane | auto (not used) | `fd00:0:0:0:3:8000:0:3` | IPv6 routes to SR domain (r1, rr)           |
| r0         | `louisroyer/dev-nextmn-srv6`        | r0        | disabled        | `fc00:2:1::/48`         | End.DX4                                     |
| r0         | `louisroyer/dev-nextmn-srv6`        | edge      | `10.1.5.129`    | disabled                | H.Encaps + Route to instance in edge0 (s0)  |
| r0         | `louisroyer/dev-nextmn-srv6`        | nextmndb  | auto            | auto                    |                                             |
| r1         | `louisroyer/dev-nextmn-srv6`        | control   | auto            | `fd00:0:0:0:2:8000:0:5` |                                             |
| r1         | `louisroyer/dev-nextmn-srv6`        | dataplane | auto (not used) | `fd00:0:0:0:3:8000:0:4` | IPv6 routes to SR domain (r0, rr)           |
| r1         | `louisroyer/dev-nextmn-srv6`        | r1        | disabled        | `fc00:3:1::/48`         | End.DX4                                     |
| r1         | `louisroyer/dev-nextmn-srv6`        | edge      | `10.1.5.130`    | disabled                | H.Encaps + Route to instances in edge1 (s1) |
| r1         | `louisroyer/dev-nextmn-srv6`        | nextmndb  | auto            | auto                    |                                             |
| rr         | `louisroyer/dev-nextmn-srv6`        | control   | auto            | `fd00:0:0:0:2:8000:0:3` |                                             |
| rr         | `louisroyer/dev-nextmn-srv6`        | dataplane | auto (not used) | `fd00:0:0:0:3:8000:0:3` | IPv6 routes to SR domain (srgw0, r0, r1)    |
| rr         | `louisroyer/dev-nextmn-srv6`        | rr        | disabled        | `fc00:4:1::/48`         | End                                         |
| rr         | `louisroyer/dev-nextmn-srv6`        | nextmndb  | auto            | auto                    |                                             |
| s0         | `nginx`                             | edge      | `10.1.5.131`    | disabled                | Route to slice0 via r0                      |
| s0         | `ngnix`                             | service   | `10.4.0.1`      | disabled                |                                             |
| s1         | `nginx`                             | edge      | `10.1.5.132`    | disabled                | Route to slice0 via r1                      |
| s1         | `ngnix`                             | service   | `10.4.0.1`      | disabled                |                                             |
| srv6-ctrl  | `louisroyer/dev-nextmn-srv6-ctrl`   | control   | `10.1.3.132`    | `fd00:0:0:0:2:8000:0:2` |                                             |
| amf        | `louisroyer/dev-free5gc-amf`        | control   | `10.1.3.133`    | auto                    |                                             |
| amf        | `louisroyer/dev-free5gc-amf`        | sbi       | `10.1.1.129`    | disabled                |                                             |
| smf        | `louisroyer/dev-free5gc-smf`        | control   | `10.1.3.134`    | auto                    |                                             |
| smf        | `louisroyer/dev-free5gc-smf`        | sbi       | `10.1.1.130`    | disabled                |                                             |
| nrf        | `louisroyer/dev-free5gc-nrf`        | sbi       | `10.1.1.131`    | disabled                |                                             |
| nrf        | `louisroyer/dev-free5gc-nrf`        | db        | auto            | disabled                |                                             |
| ausf       | `louisroyer/dev-free5gc-ausf`       | sbi       | `10.1.1.132`    | disabled                |                                             |
| nssf       | `louisroyer/dev-free5gc-nssf`       | sbi       | `10.1.1.133`    | disabled                |                                             |
| pcf        | `louisroyer/dev-free5gc-pcf`        | sbi       | `10.1.1.134`    | disabled                |                                             |
| pcf        | `louisroyer/dev-free5gc-pcf`        | db        | auto            | disabled                |                                             |
| udm        | `louisroyer/dev-free5gc-udm`        | sbi       | `10.1.1.135`    | disabled                |                                             |
| udr        | `louisroyer/dev-free5gc-udr`        | sbi       | `10.1.1.136`    | disabled                |                                             |
| udr        | `louisroyer/dev-free5gc-udr`        | db        | auto            | disabled                |                                             |
| chf        | `louisroyer/dev/free5gc-chf`        | sbi       | `10.1.1.137`    | disabled                |                                             |
| chf        | `louisroyer/dev/free5gc-chf`        | db        | auto            | disabled                |                                             |
| webconsole | `louisroyer/dev/free5gc-webconsole` | sbi       | `10.1.1.138`    | disabled                |                                             |
| webconsole | `louisroyer/dev/free5gc-webconsole` | db        | auto            | disabled                |                                             |
| upfi       | `louisroyer/dev-free5gc-upf`        | control   | `10.1.3.135`    | auto                    |                                             |
| upfi       | `louisroyer/dev-free5gc-upf`        | dataplane | `10.1.4.132`    | auto (not used)         |                                             |
| upfa1      | `louisroyer/dev-free5gc-upf`        | control   | `10.1.3.136`    | auto                    |                                             |
| upfa1      | `louisroyer/dev-free5gc-upf`        | dataplane | `10.1.4.133`    | auto (not used)         |                                             |
| upfa1      | `louisroyer/dev-free5gc-upf`        | edge      | `10.1.4.133`    | auto (not used)         |                                             |
| upfa2      | `louisroyer/dev-free5gc-upf`        | control   | `10.1.3.137`    | auto                    |                                             |
| upfa2      | `louisroyer/dev-free5gc-upf`        | dataplane | `10.1.4.134`    | auto (not used)         |                                             |
| upfa2      | `louisroyer/dev-free5gc-upf`        | edge      | `10.1.4.134`    | auto (not used)         |                                             |
| populate   | `louisroyer/free5gc-populate`       | db        | auto            | disabled                |                                             |
| mongodb    | `mongodb`                           | db        | auto            | disabled                |                                             |
| nextmndb   | `postgres`                          | nextmndb  | auto            | auto                    |                                             |
