#!/bin/bash
# 
# ***** BEGIN LICENSE BLOCK *****
# Zimbra Collaboration Suite Server
# Copyright (C) 2005, 2007, 2008, 2009, 2010, 2013, 2014, 2016 Synacor, Inc.
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software Foundation,
# version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with this program.
# If not, see <https://www.gnu.org/licenses/>.
# ***** END LICENSE BLOCK *****
# 


accounts=`zmprov gaa`

for a in $accounts; do
    mh=`zmprov ga $a | grep '^zimbraMailHost' | awk -F: '{ print $2; }'`
    cmd="zmprov ma $a zimbraMailHost $mh"
    if [ "x$1" = "x-f" ]; then
        echo "Running: $cmd"
        $cmd
    else
        echo "WillRun: $cmd"
    fi
done
