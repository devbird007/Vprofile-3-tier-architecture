#!/bin/bash
set -euxo pipefail

sudo yum update -y
sudo yum install epel-release -y