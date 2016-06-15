#!/bin/bash

/bin/systemctl stop firewalld
/bin/systemctl disable firewalld

# Install important Packages
/usr/bin/yum -y install git
