# How to test

## Runtime instance update

1. `make pull`
2. `make set/dataplane/nextmn-srv6 && make set/nb-ue/1 && make set/nb-edges/2`
3. `make u`
4. `make ctrl` ; In the web browser, look for uplink `srgw` rule `UUID` for your UE
5. Enable uplink rule using `curl -X PATCH http://[fd00::2:8000:0:3]:8080/rules/{UUID}/enable` (replace `{UUID}` with rule's UUID) ; edges are pre-configured with downlink path to your UE.
6. `make t/ue1` and `ping 10.4.0.1`
7. `make t/s0`/`make t/s1` and `tshark -i any`
8. Enable new uplink rule & disable old uplink rule using `curl -X PATCH http://[fd00::2:8000:0:3]:8080/rules/{UUID}/enable && curl -X PATCH http://[fd00::2:8000:0:3]:8080/rules/{UUID}/disable` (replace `{UUID}` with rule's UUID).
9. When done with the test, `make d`
