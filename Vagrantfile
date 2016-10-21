require 'yaml'
require 'fileutils'

config = {
  local: './vagrant/config/vagrant-local.yml',
  example: './vagrant/config/vagrant-local.example.yml'
}

# copy config from example if local config not exists
FileUtils.cp config[:example], config[:local] unless File.exist?(config[:local])

# read config
options = YAML.load_file config[:local]

# check github token
if options['github_token'].nil? || options['github_token'].to_s.length != 40
  puts "You must place REAL GitHub token into configuration:\n/yii2-app-services/vagrant/config/vagrant-local.yml"
  exit
end

domains = {
  frontend: options['domain_name'],
  backend:  "admin.#{options['domain_name']}",
  xhprof:  "xh.#{options['domain_name']}",
}

# vagrant configurate
Vagrant.configure(2) do |config|
  # select the box
  if options.has_key?('vm_box')
    config.vm.box = options['vm_box']
  else
    config.vm.box = options['domain_name']
  end

  if options.has_key?('vm_box_url')
    config.vm.box_url = options['vm_box_url']
  end

  # should we ask about box updates?
  config.vm.box_check_update = options['box_check_update']

  config.vm.provider 'virtualbox' do |vb|
    # machine cpus count
    vb.cpus = options['cpus']
    # machine memory size
    vb.memory = options['memory']
    # machine name (for VirtualBox UI)
    if options.has_key?('machine_name')
      vb.name = options['machine_name']
    end
  end

  if options.has_key?('machine_name')
    # machine name (for vagrant console)
    config.vm.define options['machine_name']

    # machine name (for guest machine console)
    config.vm.hostname = options['machine_name']
  end

  # network settings
  config.vm.network 'private_network', ip: options['ip']

  # sync: folder 'yii2-app-services' (host machine) -> folder '/var/www/y2as' (guest machine)
  config.vm.synced_folder './', options['app_path'], owner: 'vagrant', group: 'vagrant'

  # disable folder '/vagrant' (guest machine)
  config.vm.synced_folder '.', '/vagrant', disabled: true

  # hosts settings (host machine)
  # vagrant plugin install vagrant-hostmanager
  config.vm.provision :hostmanager
  config.hostmanager.enabled            = true
  config.hostmanager.manage_host        = true
  config.hostmanager.manage_guest       = true
  config.hostmanager.ignore_private_ip  = false
  config.hostmanager.include_offline    = true
  config.hostmanager.aliases            = domains.values

  # provisioners
  config.vm.provision 'shell', path: "./vagrant/provision/#{options['provision']}/once-as-root.sh", args: [options['timezone'], options['app_path'], options['ip'], options['db_name']]
  config.vm.provision 'shell', path: "./vagrant/provision/#{options['provision']}/once-as-vagrant.sh", args: [options['github_token'], options['app_path']], privileged: false
  config.vm.provision 'shell', path: "./vagrant/provision/#{options['provision']}/always-as-root.sh", run: 'always'

  # post-install message (vagrant console)
  config.vm.post_up_message = "Frontend URL: http://#{domains[:frontend]}\nBackend URL: http://#{domains[:backend]}\nXHprof URL: http://#{domains[:xhprof]}"
end
