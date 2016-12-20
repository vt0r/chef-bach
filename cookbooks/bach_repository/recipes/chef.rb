#
# Cookbook Name:: bach_repository
# Recipe:: chef
#
include_recipe 'bach_repository::directory'
bins_dir = node['bach']['repository']['bins_directory']

[
  [
    'https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/' \
      '14.04/x86_64/chefdk_0.12.0-1_amd64.deb',
    '6fcb4529f99c212241c45a3e1d024cc1519f5b63e53fc1194b5276f1d8695aaa'
  ],
  [
    'https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/' \
      '12.04/x86_64/chef_11.12.8-2_amd64.deb',
    '3da7460e9f03fc5d68baeeb1f50a768f880c4154626aaf78f22dac8a89e64e74'
  ],
  [
    'https://opscode-omnibus-packages.s3.amazonaws.com/ubuntu/' \
      '12.04/x86_64/chef-server_11.1.1-1_amd64.deb',
    'b6c354178cc83ec94bea40a018cef697704415575c7797c4abdf47ab996eb258'
  ]
].each do |package_url, package_checksum|

  package_name = ::File.basename(package_url)
  target_path = ::File.join(bins_dir, package_name)

  remote_file target_path do
    source package_url
    mode 0444
    checksum package_checksum
    # For whatever reason, these S3 mirrors are not very reliable.
    retries 8
  end
end
