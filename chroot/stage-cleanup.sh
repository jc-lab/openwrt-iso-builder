#!/bin/bash

set -e

export DEBIAN_FRONTEND=noninteractive

rm -rf /etc/ssh/*.key /etc/ssh/*.pub
rm -rf /etc/apt/apt.conf.d/00proxy

apt clean
