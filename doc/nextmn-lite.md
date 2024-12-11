# NextMN Lite

## PDU Session Establishment procedure

```mermaid
%%{init: { 'sequence': {'noteAlign': 'left'} , 'themeVariables':{'actorLineColor': '#333333', 'signalColor': '#000000', 'signalTextColor':'#000000'} }}%%
sequenceDiagram
actor User
participant UE
participant gNB
participant CP
participant UPF
rect LightBlue
    note over CP,UPF: PFCP Association
    CP->>+UPF: PFCP Association Setup Request
    UPF->>+CP: PFCP Association Setup Response
end
rect LightOrange
    User->>+UE: POST cli/radio/peer(gNBControl)
    note over User,UE: {<br>"gnb": "http://gnb1.example.org/",<br>}
end
rect Plum
    note over UE, gNB: RadioSim Link Establishment
    UE->>+gNB: Radio Peer(dl endpoint)
    gNB->>+UE: Radio Peer(ul endpoint)
end
rect LightOrange
    User->>+UE: POST cli/ps/establish(gNBControl, dnn)
    note over User,UE: {<br>"gnb": "http://gnb1.example.org/",<br>"dnn": "srv6",<br>}
end
rect LightGreen
    note over UE,UPF: PDU Session Establishment
    UE->>+gNB: PDU Session Estab. Req.(UEControl)
    gNB->>+CP: PDU Session Estab. Req.(UEControl, gNBControl)
    CP->>+UPF: PFCP Session Establishment Request(uplinkPDR, uplinkFAR)
    UPF->>+CP: PFCP Session Establishment Response
    CP->>+gNB: N2 PDU Session Req.(ulFTEID, UEIpAddr)
    gNB->>+UE: PDU Session Estab. Accept
    gNB->>+CP: N2 PDU Session Resp.(dlFTEID)
    CP->>+UPF: PFCP Session Modification Request(downlinkPDR, downlinkFAR)
    UPF->>+CP: PFCP Session Modification Response
end
UE<<-->>+UPF: PDUs
```

## N2 Handover Scenario 1 (preserve SRGW, preserve Anchor)
```mermaid
%%{init: { 'sequence': {'noteAlign': 'left'} , 'themeVariables':{'actorLineColor': '#333333', 'signalColor': '#000000', 'signalTextColor':'#000000'} }}%%
sequenceDiagram
actor User
participant UE
participant gNB1
participant gNB2
participant CP
participant SRv6Ctrl
participant SRGW
participant Anchor

note over UE, gNB2: gNB1 initiate N2 Handover
rect LightGreen
    gNB1->>+CP: HandoverRequired
    CP->>+SRv6Ctrl: PFCP Session Establishment(uplinkPDR, uplinkFAR)
    SRv6Ctrl->>+SRGW: create UL rule (match on new FTEID, same path)
    CP->>+gNB2: HandoverRequest
    gNB2->>+CP: HandoverRequestACK
    CP->>+SRv6Ctrl: PFCP Session Modification(downlinkPDR, downlinkPDR)
    SRv6Ctrl->>+Anchor: create DL rule (match on same UE, create SRH using gNB2 FTEID, desactivated)
    CP->>+gNB1: HandoverCommand
    gNB1->>+UE: HandoverCommand
    UE->>+gNB2: HandoverConfirm
    gNB2->>+CP: HandoverNotify
    CP->>+SRv6Ctrl: PFCP Session Modification[update FAR from BUFF to FORW]
    SRv6Ctrl->>+SRGW: create temporary DL redirect(oldFTEID, newFTEID)
    SRv6Ctrl->>+Anchor: update DL rule (desactivate old rule, activate new rule)
end
```

## N2 Handover Scenario 2 (SRGW update, preserve Anchor)
```mermaid
%%{init: { 'sequence': {'noteAlign': 'left'} , 'themeVariables':{'actorLineColor': '#333333', 'signalColor': '#000000', 'signalTextColor':'#000000'} }}%%
sequenceDiagram
actor User
participant UE
participant gNB1
participant gNB2
participant CP
participant SRv6Ctrl
participant SRGW1
participant SRGW2
participant Anchor

note over UE, gNB2: gNB1 initiate N2 Handover
rect LightGreen
    gNB1->>+CP: HandoverRequired
    CP->>+SRv6Ctrl: PFCP Session Establishment(uplinkPDR, uplinkFAR)
    SRv6Ctrl->>+SRGW2: create UL rule (match on new FTEID, path to Anchor)
    CP->>+gNB2: HandoverRequest
    gNB2->>+CP: HandoverRequestACK
    CP->>+SRv6Ctrl: PFCP Session Modification(downlinkPDR, downlinkPDR)
    SRv6Ctrl->>+Anchor: create DL rule (match on same UE, create SRH using SRGW2+gNB2 FTEID, desactivated)
    CP->>+gNB1: HandoverCommand
    gNB1->>+UE: HandoverCommand
    UE->>+gNB2: HandoverConfirm
    gNB2->>+CP: HandoverNotify
    CP->>+SRv6Ctrl: PFCP Session Modification[update FAR from BUFF to FORW]
    SRv6Ctrl->>+SRGW1: remove UL rule() + create temporary DL redirect(oldFTEID, SRGW2+newFTEID)
    SRv6Ctrl->>+Anchor: update DL rule (desactivate old rule, activate new rule)
end
```

## N2 Handover Scenario 3 (preserve SRGW, Anchor update)
```mermaid
%%{init: { 'sequence': {'noteAlign': 'left'} , 'themeVariables':{'actorLineColor': '#333333', 'signalColor': '#000000', 'signalTextColor':'#000000'} }}%%
sequenceDiagram
actor User
participant UE
participant gNB1
participant gNB2
participant CP
participant SRv6Ctrl
participant SRGW
participant Anchor1
participant Anchor2

note over UE, gNB2: gNB1 initiate N2 Handover
rect LightGreen
    gNB1->>+CP: HandoverRequired
    CP->>+SRv6Ctrl: PFCP Session Establishment(uplinkPDR, uplinkFAR)
    SRv6Ctrl->>+SRGW: create UL rule (match on new FTEID, path to Anchor2, desactivated)
    CP->>+gNB2: HandoverRequest
    gNB2->>+CP: HandoverRequestACK
    CP->>+SRv6Ctrl: PFCP Session Modification(downlinkPDR, downlinkPDR)
    SRv6Ctrl->>+Anchor1: create temporary DL rule (match on UE, create SRH using SRGW+gnb2 FTEID)
    SRv6Ctrl->>+Anchor2: create DL rule (match on UE, create SRH using SRGW+gNB2 FTEID)
    SRv6Ctrl->>+SRGW: update UL rule (remove old rule, activate new rule)
    CP->>+gNB1: HandoverCommand
    gNB1->>+UE: HandoverCommand
    UE->>+gNB2: HandoverConfirm
    gNB2->>+CP: HandoverNotify
    CP->>+SRv6Ctrl: PFCP Session Modification[update FAR from BUFF to FORW]
    SRv6Ctrl->>+SRGW: remove old UL rule(), activate new UL rule() + create temporary DL redirect(oldFTEID, newFTEID)
end
```

## N2 Handover Scenario 4 (SRGW update, Anchor update)
```mermaid
%%{init: { 'sequence': {'noteAlign': 'left'} , 'themeVariables':{'actorLineColor': '#333333', 'signalColor': '#000000', 'signalTextColor':'#000000'} }}%%
sequenceDiagram
actor User
participant UE
participant gNB1
participant gNB2
participant CP
participant SRv6Ctrl
participant SRGW1
participant SRGW2
participant Anchor1
participant Anchor2

note over UE, gNB2: gNB1 initiate N2 Handover
rect LightGreen
    gNB1->>+CP: HandoverRequired
    CP->>+SRv6Ctrl: PFCP Session Establishment(uplinkPDR, uplinkFAR)
    SRv6Ctrl->>+SRGW2: create UL rule (match on new FTEID, path to Anchor2)
    CP->>+gNB2: HandoverRequest
    gNB2->>+CP: HandoverRequestACK
    CP->>+SRv6Ctrl: PFCP Session Modification(downlinkPDR, downlinkPDR)
    SRv6Ctrl->>+Anchor1: update DL rule to temporary (match on UE, create SRH using SRGW2+gnb2 FTEID)
    SRv6Ctrl->>+Anchor2: create DL rule (match on UE, create SRH using SRGW2+gNB2 FTEID)
    SRv6Ctrl->>+SRGW1: update UL rule (remove old rule, activate new rule)
    CP->>+gNB1: HandoverCommand
    gNB1->>+UE: HandoverCommand
    UE->>+gNB2: HandoverConfirm
    gNB2->>+CP: HandoverNotify
    CP->>+SRv6Ctrl: PFCP Session Modification[update FAR from BUFF to FORW]
    SRv6Ctrl->>+SRGW1: remove old UL rule()
end
```
