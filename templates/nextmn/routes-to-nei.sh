#!/usr/bin/env sh
# Copyright Louis Royer and the NextMN contributors. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

set -e

while
	IFS=' ' read -r current_addr NEI_ADDR <<EOF
$NEI_ADDR
EOF
	IFS=' ' read -r current_nh NEI_NH <<EOF
$NEI_NH
EOF
	[ -n "$current_addr" ] && [ -n "$current_nh" ]
do
	ip route replace "$current_addr" via "$current_nh"
done
