# chefgithook cookbook

This sets up a very simple Sinatra server that listens for GitHub Web Hook
calls about your Chef repo and automatically uploads any updated assets
to your Chef server.

# Requirements

- A [GitHub](http://github.com) account
- A [Chef](http://www.getchef.com) account

We have only tested this with Hosted Chef, but there is no reason it should not
also work with Enterprise Chef and Open Source Chef.

# Chef Account Setup

ChefGitHook requires an admin account on the chef server.  Note that, at least
with Hosted Chef (and probably Enterprise Chef), it is not sufficient to create
a new client and grant it lots of privileges, you must actually create a new
"user" for use with this tool.

The Chef user/client/node name is configurable but it is set to `gitupdater` by default.

# Server Setup

- Allow connections from the GitHub IPs (listed on their website) to port
6969 (configurable, below) on the node running this cookbook.

# Usage

Add this to a wrapper cookbook or a run list and configure a few of the
necessary attributes and you should be good to go.

# S3 Bucket Setup

ChefGitHook expects your chef credentials to be in an S3 bucket (specified in a required attribute below).  By default they should be stored in `/keys/chefgithook`.

## Files

The following files are required:

- `chefupdater_id_rsa` - The private key with permission to access your git repo.
- `client.pem` - The client key for the Chef admin user account
- `YOUR_VALIDATOR_FILE.pem` - The validator key, where YOUR_VALIDATOR_FILE should be replaced by your **validation_client_name** (configurable in a required attribute below).

## IAM Permission Setup

It is strongly recommended that you configure some security around the key
bucket so as to prevent it from being accessible to anyone other than the
ChefGitHook user.  The following IAM security policy should be sufficient to
provide restricted access to the proper S3 bucket:

    {
      "Statement": [
        {
          "Sid": "StmtListBuckets",
          "Action": [
            "s3:ListAllMyBuckets",
            "s3:ListBucket"
          ],
          "Effect": "Allow",
          "Resource": [ "arn:aws:s3:::*" ]
        },
        {
          "Sid": "StmtFileAccess",
          "Action": "s3:GetObject*",
          "Effect": "Allow",
          "Resource": [
            "arn:aws:s3:::YOUR_BUCKET_NAME/keys/chefgithook/*"
          ]
        }
      ]
    }

**Be sure to replace YOUR_BUCKET_NAME with your actual bucket name**

## AWS Credentials Data Bag format:

    {
      "id": "aws_credentials",
      "chefgithook": {
        "access_key_id": "YOUR_ACCESS_KEY_ID",
        "secret_access_key": "YOUR_SECRET_KEY"
      }
    }

# Attributes

Required:

- `['chefgithook']['knife']['validation_client_name']` - Your Chef validation client name
- `['chefgithook']['s3']['bucket']` - S3 Bucket where your Chef credentials are located
- `['chefgithook']['chef_repo']` - The GitHub repo where your Chef assets live

Optional:

- `['chefgithook']['knife']['node_name']` - The Chef admin user account name (default: 'gitupdater')
- `['chefgithook']['home']` - The home directory of the daemon account
- `['chefgithook']['s3']['path']` - Path within the S3 bucket where credentials files live (default: '/keys/chefgithook')
- `['chefgithook']['s3']['key_source']['data_bag']` - S3 API Key Data Bag (default: 'secrets')
- `['chefgithook']['s3']['key_source']['data_bag_item']` -  S3 API Key Data Bag Item (default: 'aws_credentials')
- `['chefgithook']['s3']['key_source']['data_bag_item_key']` - S3 API Key Data Bag Item Hash Key (default: 'chefgithook')
- `['chefgithook']['user']` - UNIX user account for the daemon (default: 'chefupdater')
- `['chefgithook']['group']` - UNIX group for the daemon (default: 'chefupdater')
- `['chefgithook']['chef_repo_tag']` - The tag or hash to pull from the Chef Git Repo (default: 'master')
- `['chefgithook']['sinatra']['port']` - The port where the Sinatra daemon listens (default: 6969)

# Author

Author:: EverTrue, Inc. (<eric.herot@evertrue.com>)
