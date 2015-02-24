#
# Cookbook Name:: chefgithook
# Recipe:: default
#
# Copyright (C) 2014 EverTrue, Inc.
#
# All rights reserved - Do Not Redistribute
#

chef_gem 'sinatra'
chef_gem 'awesome_print'

# aws_keys = Chef::EncryptedDataBagItem.load(
#     node['chefgithook']['s3']['key_source']['data_bag'],
#     node['chefgithook']['s3']['key_source']['data_bag_item']
#   )
aws_keys = data_bag_item('secrets', 'aws_credentials')
s3_keys = aws_keys[node['chefgithook']['s3']['key_source']['data_bag_item_key']]

user node['chefgithook']['user'] do
  action :create
  shell '/bin/bash'
  comment 'Chef Updater'
  home node['chefgithook']['home']
  supports manage_home: true
end

%w{
  chef-updater
  .chef
}.each do |dir|
  directory "#{node['chefgithook']['home']}/#{dir}" do
    owner node['chefgithook']['user']
    group node['chefgithook']['group']
    mode '0755'
    action :create
  end
end

directory "#{node['chefgithook']['home']}/.ssh" do
  owner node['chefgithook']['user']
  group node['chefgithook']['group']
  mode '0700'
  action :create
end

cookbook_file "#{node['chefgithook']['home']}/.ssh/known_hosts" do
  source 'github_known_hosts'
  owner node['chefgithook']['user']
  group node['chefgithook']['group']
  mode '0755'
end

template "#{node['chefgithook']['home']}/chef-updater/git_ssh.sh" do
  source 'git_ssh_sh.erb'
  owner node['chefgithook']['user']
  group node['chefgithook']['group']
  mode '0755'
end

s3_file "#{node['chefgithook']['home']}/.ssh/id_rsa" do
  remote_path "#{node['chefgithook']['s3']['path']}/chefupdater_id_rsa"
  bucket node['chefgithook']['s3']['bucket']
  aws_access_key_id s3_keys['access_key_id']
  aws_secret_access_key s3_keys['secret_access_key']
  owner node['chefgithook']['user']
  group node['chefgithook']['group']
  mode '0600'
end

package 'git'

git "#{node['chefgithook']['home']}/chef-updater/server-chef" do
  repository node['chefgithook']['chef_repo']
  reference node['chefgithook']['chef_repo_tag']
  user node['chefgithook']['user']
  group node['chefgithook']['group']
  action :checkout
end

[
  'client.pem',
  "#{node['chefgithook']['knife']['validation_client_name']}.pem"
].each do |file|
  s3_file "#{node['chefgithook']['home']}/.chef/#{file}" do
    remote_path "#{node['chefgithook']['s3']['path']}/#{file}"
    bucket node['chefgithook']['s3']['bucket']
    aws_access_key_id s3_keys['access_key_id']
    aws_secret_access_key s3_keys['secret_access_key']
    owner node['chefgithook']['user']
    group node['chefgithook']['group']
    mode '0600'
  end
end

template "#{node['chefgithook']['home']}/chef-updater/updater.rb" do
  source 'updater.rb'
  owner node['chefgithook']['user']
  group node['chefgithook']['group']
  mode '0755'
  notifies :restart, 'runit_service[chef-updater]'
end

case node.chef_environment
when 'prod', 'production'
  rack_env = 'production'
else
  rack_env = 'test'
end

include_recipe 'runit'

runit_service 'chef-updater' do
  env(
    'KNIFE_NODE_NAME' => 'gitupdater',
    'KNIFE_CLIENT_KEY' => "#{node['chefgithook']['home']}/.chef/client.pem",
    'KNIFE_VALIDATION_CLIENT_NAME' => node['chefgithook']['knife']['validation_client_name'],
    'KNIFE_VALIDATION_CLIENT_KEY' => "#{node['chefgithook']['home']}/.chef/evertrue-validator.pem",
    'ET_EMAIL' => 'user@domain.com',
    'CHEF_REPO_DIR' => "#{node['chefgithook']['home']}/chef-updater/server-chef"
  )
  options(rack_env: rack_env)
  default_logger true
end
