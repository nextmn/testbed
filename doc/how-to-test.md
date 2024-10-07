# How to test

## Runtime instance update

1. `make pull`
2. `make set/dataplane/nextmn-srv6 && make set/nb-ue/1 && make set/nb-edges/2`
3. `make u`
4. `make t/ue1` and `ping 10.4.0.1`
5. `make t/s0`/`make t/s1` and optinaly add latency on an instance with for example `tc qdisc add dev edge-0 root netem delay 20ms`; then start capture with `tshark -i edge-0 -f icmp`
6. `make ue/switch-edge/1` to swich between edges
8. When done with the test, `make d`

Alternatively: `make graph/latency-switch`
