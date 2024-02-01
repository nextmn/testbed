#!/usr/bin/env bash
# Copyright 2024 Louis Royer. All rights reserved.
# Use of this source code is governed by a MIT-style license that can be
# found in the LICENSE file.
# SPDX-License-Identifier: MIT

set -e
IFS=$' '

read -r -a NEI_NH_ARR <<< "${NEI_NH}"

read -r -a NEI_ADDR_ARR <<< "${NEI_ADDR}"

if [ ${#NEI_NH_ARR[@]} -ne ${#NEI_ADDR_ARR[@]} ]; then
	exit 1
fi

i=0
while [ $i -le $((${#NEI_NH_ARR[@]} - 1)) ]; do
	ip route replace "${NEI_ADDR_ARR[$i]}" via "${NEI_NH_ARR[$i]}"
	i=$((i+1))
done
