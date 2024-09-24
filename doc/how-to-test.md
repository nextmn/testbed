# How to test

## Runtime instance update

1. `make pull`
2. `make set/dataplane/nextmn-srv6 && make set/nb-ue/1 && make set/nb-edges/2`
3. `make u`
4. `make t/ue1` and `ping 10.4.0.1`
5. `make t/s0`/`make t/s1` and `tshark -i any -f icmp`
6. `make ctrl` ; In the web browser, look for uplink `srgw` rule `UUID` for your UE
7. Enable new uplink rule & disable old uplink rule using `curl -X PATCH http://[fd00::2:8000:0:3]:8080/rules/{UUID}/enable && curl -X PATCH http://[fd00::2:8000:0:3]:8080/rules/{UUID}/disable` (replace `{UUID}` with rule's UUID).
8. When done with the test, `make d`
