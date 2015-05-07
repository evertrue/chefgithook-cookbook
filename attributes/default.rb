default['chefgithook']['knife']['node_name'] = 'gitupdater'
default['chefgithook']['knife']['validation_client_name'] = 'default'
default['chefgithook']['home'] = '/home/chefupdater'

default['chefgithook']['s3']['path'] = '/keys/chefgithook'
default['chefgithook']['s3']['bucket'] = nil
default['chefgithook']['s3']['key_source']['data_bag'] = 'secrets'
default['chefgithook']['s3']['key_source']['data_bag_item'] = 'aws_credentials'
default['chefgithook']['s3']['key_source']['data_bag_item_key'] = 'chefgithook'

default['chefgithook']['user'] = 'chefupdater'
default['chefgithook']['group'] = 'chefupdater'
default['chefgithook']['chef_repo'] = nil
default['chefgithook']['chef_repo_tag'] = 'master'

default['chefgithook']['sinatra']['port'] = '6969'

default['chefgithook']['secret'] = ''
