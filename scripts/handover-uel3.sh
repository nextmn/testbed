#!/usr/bin/env bash
# Copyright 2025 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT
#
curl -X POST --json '
	{
		"ue-ctrl": "http://[fd00:0:0:0:2:8000:0:c]:8080",
		"gnb-target": "http://[fd00:0:0:0:2:8000:0:8]:8080",
		"sessions": [{
			"ue-addr": "10.2.1.1",
			"dnn": "free5gc"
		}]}' "http://[fd00::2:8000:0:7]:8080/cli/ps/handover"
