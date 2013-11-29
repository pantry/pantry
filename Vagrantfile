Vagrant::Environment.class_eval do
  define_method :default_provider do
    :vmware_fusion
  end
end

# Set up a Vagrant box with pantry-server and one pantry-client,
# port forwarded directly so that you can connect to localhost:23001 and localhost:23002
# and run pantry CLI locally
#
# Defaults to VMWare but VirtualBox also supported
Vagrant::Config.run("2") do |config|

  config.vm.provider :virtualbox do |vbox, config|
    config.vm.box     = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  end

  config.vm.provider :vmware_fusion do |vmware, config|
    config.vm.box     = "precise64"
    config.vm.box_url = "http://files.vagrantup.com/precise64_vmware_fusion.box"
  end

  # Expose Server ports outside of the VM for local pantry cli usage
  config.vm.network "forwarded_port", guest: 23001, host: 23001, autocorrect: true
  config.vm.network "forwarded_port", guest: 23002, host: 23002, autocorrect: true

  # Install the current pantry.gem
  config.vm.provision :shell do |shell|
    shell.inline = <<-EOF.gsub(/^ +/, "")
      # Make sure vagrant always has sudo access
      ( cat << 'EOP'
        Defaults exempt_group=vagrant
        %vagrant ALL=NOPASSWD:ALL
      EOP
      ) > /etc/sudoers.d/vagrant
      chmod 0440 /etc/sudoers.d/vagrant

      # Remove vagrant default Ruby
      if [ -d /opt/ruby ]; then
        rm -rf /opt/ruby
      fi

      # Install Ruby 2.0
      if [ ! -f /usr/bin/ruby ]; then
        apt-get update
        apt-get install -y python-software-properties
        apt-add-repository -y ppa:brightbox/ruby-ng-experimental
        apt-get update
        apt-get install -y ruby2.0 ruby2.0-dev
      fi

      # Install ZeroMQ 3
      if [ ! -f /usr/lib/x86_64-linux-gnu/libzmq3.so ]; then
        apt-add-repository ppa:chris-lea/zeromq
        apt-get update
        apt-get install -y libzmq3 libzmq3-dev
      fi

      # Install latest version of the gem
      gem install /vagrant/pantry*.gem

      # Copy configs in place
      mkdir -p /etc/pantry
      cp /vagrant/dist/client.yml /etc/pantry/client.yml
      cp /vagrant/dist/server.yml /etc/pantry/server.yml
      cp /vagrant/dist/upstart/pantry-client.conf /etc/init/pantry-client.conf
      cp /vagrant/dist/upstart/pantry-server.conf /etc/init/pantry-server.conf

      # Restart pantry services
      restart pantry-server || start pantry-server
      restart pantry-client || start pantry-client
    EOF
  end
end

# vi: set ft=ruby
