#!/bin/bash

/bin/systemctl stop firewalld
/bin/systemctl disable firewalld

# Install Important packages
/usr/bin/yum -y install git
