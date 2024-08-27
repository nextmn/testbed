# How to test

## Runtime instance update

1. `make pull`
2. `make set/dataplane/nextmn-srv6 && make set/nb-ue/1 && make set/nb-edges/2`
3. `make u`
4. `make ctrl`
5. In the web browser, look for uplink `srgw` rule `UUID` for your UE
6. Enable uplink rule using `curl -X PATCH http://[fd00::2:8000:0:3]:8080/rules/{UUID}/enable` (replace `{UUID}` with rule's UUID)
7. In the web browser, look for downlink `r0`/`r1` rule `UUID` for your UE
8. Enable downlink rule using `curl -X PATCH http://[fd00::2:8000:0:4]:8080/rules/{UUID}/enable`/`curl -X PATCH http://[fd00::2:8000:0:5]:8080/rules/{UUID}/enable` (replace `{UUID}` with rule's UUID)
9. `make t/ue1` and `ping 10.4.0.1`
10. `make t/s0`/`make t/s1` and `tshark -i any`
11. Enable new uplink rule & disable old uplink rule
12. When done with the test, `make d`
