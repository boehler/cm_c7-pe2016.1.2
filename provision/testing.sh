#!/bin/bash

/bin/systemctl stop firewalld
/bin/systemctl disable firewalld

# Install Important Packages
/usr/bin/yum -y install git
