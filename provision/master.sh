#!/bin/bash

# Setup the "run" environment
export PATH=$PATH:/opt/puppetlabs/puppet/bin/

# Turn off and disable the Firewall
/bin/systemctl stop firewalld.service
/bin/systemctl disable firewalld.service

# Install Hunner's Hiera Module
/opt/puppetlabs/puppet/bin/puppet module install 'hunner-hiera'

# Setup the Hiera configuration
  cat > /var/tmp/configure_hiera.pp << 'EOF'
    class { 'hiera':
      hiera_yaml => '/etc/puppetlabs/puppet/hiera.yaml',
      hierarchy  => [
        'nodes/%{clientcert}',
        '%{environment}',
        'common',
      ],
      logger     => 'console',
      datadir    => '/etc/puppetlabs/code/environments/%{environment}/hieradata'
    }
EOF

# Configure Hiera
/opt/puppetlabs/puppet/bin/puppet apply /var/tmp/configure_hiera.pp

# Configure Puppet to point to hiera.yaml
/opt/puppetlabs/puppet/bin/puppet module install 'puppetlabs-inifile'

cat > /var/tmp/configure_puppet.pp << 'EOF'
  ini_setting { 'configure puppet':
    ensure  => 'present',
    path    => '/etc/puppetlabs/puppet/puppet.conf',
    section => 'main',
    setting => 'hiera_config',
    value   => '$confdir/hiera.yaml',
  }
EOF

# Create Code manager Deploy Role
curl -k -X POST -H 'Content-Type: application/json' https://master.puppetlabs.vm:4433/rbac-api/v1/roles -d '{"permissions": [{"object_type": "environment", "action": "deploy_code", "instance": "*"}, {"object_type": "tokens", "action": "override_lifetime", "instance": "*"}],"user_ids": [], "group_ids": [], "display_name": "CM Admin", "description": ""}' --cert /etc/puppetlabs/puppet/ssl/certs/master.puppetlabs.vm.pem --key /etc/puppetlabs/puppet/ssl/private_keys/master.puppetlabs.vm.pem --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem

# Create Code Manager Deploy User
curl -k -X POST -H 'Content-Type: application/json' https://master.puppetlabs.vm:4433/rbac-api/v1/users -d '{"login":"cmadmin","email":"cmadmin@master.puppetlabs.vm","display_name":"CM Admin","role_ids": [4],"password":"puppetlabs"}' --cert /etc/puppetlabs/puppet/ssl/certs/master.puppetlabs.vm.pem --key /etc/puppetlabs/puppet/ssl/private_keys/master.puppetlabs.vm.pem --cacert /etc/puppetlabs/puppet/ssl/certs/ca.pem

# Set up the Puppet Access Configuration
mkdir ~/.puppetlabs
echo '{"service-url":"https://master.puppetlabs.vm:4433/rbac-api"}' > ~/.puppetlabs/puppet-access.conf

# Generate Deployment Token
echo "puppetlabs" | /opt/puppetlabs/bin/puppet-access login --username cmadmin --service-url https://master.puppetlabs.vm:4433/rbac-api --lifetime 180d

# Create SSH Key Location
mkdir -p /etc/puppetlabs/puppetserver/ssh

# Generate SSH Keys
/usr/bin/ssh-keygen -t rsa -b 4096 -C "Puppet Vagrant" -f /etc/puppetlabs/puppetserver/ssh/id-control_repo.rsa -P ""

# Set Permissions on keys
chown -R pe-puppet:pe-puppet /etc/puppetlabs/puppetserver/ssh

# Add Important Packages
/usr/bin/yum -y install git
