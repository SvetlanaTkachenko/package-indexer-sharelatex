# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
	# Phusion provided docker friendly Ubuntu 12.04 images.
	config.vm.box = "phusion-open-ubuntu-14.04-amd64"
	config.vm.box_url = "https://oss-binaries.phusionpassenger.com/vagrant/boxes/latest/ubuntu-14.04-amd64-vbox.box"

	config.ssh.forward_agent = true

	config.vm.network "forwarded_port", guest: 3022, host: 3022

	config.vm.provider "virtualbox" do |v|
		v.memory = 2048
	end

	config.vm.provision "shell" do |s|
		s.inline = <<-SCRIPT
			export DEBIAN_FRONTEND=noninteractive

			apt-get remove grub-pc

			apt-get update
			apt-get -y upgrade

			apt-get install -y curl git build-essential libtool zlib1g-dev \
        inotify-tools software-properties-common r-base wget

		SCRIPT
		s.privileged = true
	end

	# get Anaconda
	config.vm.provision "shell" do |s|
		s.inline = <<-EOF
      echo "Installing conda"
      cd /home/vagrant
      wget https://3230d63b5fc54e62148e-c95ac804525aac4b6dba79b00b39d1d3.ssl.cf1.rackcdn.com/Anaconda-2.3.0-Linux-x86_64.sh
      bash Anaconda-2.3.0-Linux-x86_64.sh -b
		EOF
		s.privileged = true
	end

	config.vm.provision "shell" do |s|
		s.inline = <<-EOF
      echo "Installing BiocLite"
      echo 'source("http://bioconductor.org/biocLite.R");biocLite()' | sudo R --no-save
		EOF
		s.privileged = true
	end

	config.vm.provision "shell" do |s|
		s.inline = <<-EOF
			curl https://raw.githubusercontent.com/creationix/nvm/v0.17.3/install.sh | bash
			export NVM_DIR="/home/vagrant/.nvm"
			[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
			nvm install 0.10
			nvm use 0.10
			echo "nvm use 0.10" >> ~/.profile
			npm install -g grunt-cli

			echo "export SHARELATEX_CONFIG=~/settings.development.coffee" >> ~/.profile

			# Change to project directory in local file system
			cd /vagrant

		EOF
		s.privileged = false
	end

	config.vm.provision "shell" do |s|
		s.inline = <<-EOF
      echo "done"
    EOF
	end

end
