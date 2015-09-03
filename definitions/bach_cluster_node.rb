#
# Cookbook Name:: bach-cluster
# Definition:: bach_cluster_node
#
# This definition handles all the boilerplate for Vagrant-based cluster nodes.
#
# This should really be a LWRP or something.  It's cumbersome to not
# have a single resource object that caches the previously set values.
#

chef_client_config =
  <<-EOM.gsub(/^ {4}/,'')
    # Unfortunately, we are using an IP addr in the chef URL.
    # For at least the first run, SSL validation is disabled.
    verify_api_cert false
    ssl_verify_mode :verify_none
  EOM

define :bach_cluster_node do
  name = params[:name]
  cpus = params[:cpus] || 1
  memory = params[:memory] || 3072
  management_ip = params[:management_ip]
  management_netmask = params[:management_netmask]
  storage_ip = params[:storage_ip] || management_ip
  storage_ip = params[:storage_netmask] || management_netmask
  floating_ip = params[:floating_ip] || management_ip
  floating_ip = params[:floating_netmask] || management_netmask
  runlist = params[:run_list]
  fqdn = fqdn_for(name)
  cfg_path =  "#{Chef::Config[:file_cache_path]}/#{fqdn}.cfg"
  
  template cfg_path do
    source 'vm_configuration.rb.erb'
    mode 0644
    variables({
               name: name,
               cpus: cpus,
               fqdn: fqdn,
               memory: memory,
               management_ip: management_ip,
               management_netmask: management_netmask,
               # storage_ip: '10.0.101.4',
               # storage_netmask: '255.255.255.240',
               # floating_ip: '10.0.101.4',
               # floating_netmask: '255.255.255.240',
              })
  end.run_action(:create)

  machine fqdn do
    add_machine_options(:vagrant_config => File.read(cfg_path))
    add_machine_options(:convergence_options => 
                        {
                         :chef_config => chef_client_config,
                         :ssl_verify_mode => :verify_none
                        })
    chef_server chef_server_config_hash
    chef_environment node.chef_environment  
    files cert_files_hash

    # We pass a list of items into the definition.
    # Total apply those items to the resource, we have to generate method calls.
    params[:run_list].each do |item|
      raise "\"#{item}\" is not marked as a role or recipe." unless
        match_data = item.match(/^(?<type>role|recipe)\[(?<name>.+)\]$/)
      send(match_data[:type].to_s, match_data[:name])
    end

    complete(params[:complete]) if params[:complete]
    converge(params[:converge]) if params[:converge]
  end
end
