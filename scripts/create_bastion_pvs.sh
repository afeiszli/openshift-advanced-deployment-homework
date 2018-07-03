#!/bin/bash

./create_5G_pvs.sh
./create_10G_pvs.sh
cat /root/pvs/* | oc create -f -
