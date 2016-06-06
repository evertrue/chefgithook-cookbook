#
# Cookbook Name:: chefgithook
# Recipe:: default
#
# Copyright (C) 2015 EverTrue, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

chef_gem 'sinatra'
chef_gem 'slack-notifier'
chef_gem 'awesome_print'
chef_gem 'vault'
chef_gem 'awsutils'

aws_keys = data_bag_item('secrets', 'aws_credentials')
s3_keys = aws_keys[node['chefgithook']['s3']['key_source']['data_bag_item_key']]

user node['chefgithook']['user'] do
  action :create
  shell '/bin/bash'
  comment 'Chef Updater'
  home node['chefgithook']['home']
  supports manage_home: true
end

%w(
  chef-updater
  .chef
).each do |dir|
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

unless node['chefgithook']['mocking']
  s3_file "#{node['chefgithook']['home']}/.ssh/id_rsa" do
    remote_path "#{node['chefgithook']['s3']['path']}/chefupdater_id_rsa"
    bucket node['chefgithook']['s3']['bucket']
    if node['chefgithook']['s3']['bucket'] =~ /\./
      s3_url "https://s3.amazonaws.com/#{node['chefgithook']['s3']['bucket']}"
    end
    aws_access_key_id s3_keys['access_key_id']
    aws_secret_access_key s3_keys['secret_access_key']
    owner node['chefgithook']['user']
    group node['chefgithook']['group']
    mode '0600'
  end

  package 'git'

  git "#{node['chefgithook']['home']}/chef-updater/server-chef" do
    repository "git@github.com:#{node['chefgithook']['chef_repo']}.git"
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
      if node['chefgithook']['s3']['bucket'] =~ /\./
        s3_url "https://s3.amazonaws.com/#{node['chefgithook']['s3']['bucket']}"
      end
      aws_access_key_id s3_keys['access_key_id']
      aws_secret_access_key s3_keys['secret_access_key']
      owner node['chefgithook']['user']
      group node['chefgithook']['group']
      mode '0600'
    end
  end
end

api_keys = data_bag_item('secrets', 'api_keys')
vault_tokens = data_bag_item('vault', 'tokens')

slack_webhook_url = api_keys['slack_webhook_url']
fail 'Slack webhook URL not found' if slack_webhook_url.nil? ||
                                      slack_webhook_url.empty?

template "#{node['chefgithook']['home']}/chef-updater/updater.rb" do
  source 'updater.rb.erb'
  owner node['chefgithook']['user']
  group node['chefgithook']['group']
  mode '0700'
  variables(
    slack_webhook_url: slack_webhook_url
  )
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
    'KNIFE_CHEF_SERVER' => node['chefgithook']['knife']['chef_server'],
    'KNIFE_VALIDATION_CLIENT_NAME' =>
      node['chefgithook']['knife']['validation_client_name'],
    'KNIFE_VALIDATION_CLIENT_KEY' => "#{node['chefgithook']['home']}/.chef/" \
      "#{node['chefgithook']['knife']['validation_client_name']}.pem",
    'ET_EMAIL' => 'user@domain.com',
    'CHEF_REPO_DIR' => "#{node['chefgithook']['home']}/chef-updater/server-chef",
    'CHEFGITHOOK_SECRET' => node['chefgithook']['secret'],
    'VAULT_PROD_WORKER_TOKEN' => vault_tokens['prod']['vault']['worker_token'],
    'VAULT_STAGE_WORKER_TOKEN' => vault_tokens['stage']['vault']['worker_token']
  )
  options(rack_env: rack_env)
  default_logger true
end
