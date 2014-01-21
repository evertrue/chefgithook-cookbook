require 'sinatra'
require 'json'
require 'rubygems'
require 'mixlib/shellout'
require 'awesome_print'

configure do
  set :port, '6969'
  set :bind, '0.0.0.0'
end

post '/' do
  push = JSON.parse(params[:payload])
  puts ap push
  ChefGithubHook.sync_to(push)
end

class ChefGithubHook

  class << self
    def chef_repo_cmd(cmd)
      command = Mixlib::ShellOut.new(cmd)
      command.cwd = ENV['CHEF_REPO_DIR']
      puts "* Running command:"
      puts "  #{cmd}"
      command.run_command
      command.error!
      return [ command.stdout, command.stderr ]
    end

    def parse_commits( commits )
      modified_files = []

      commits.each do |commit|
        modified_files += commit['added'] + commit['modified']
        modified_files -= commit['removed']
      end
      return modified_files.uniq
    end

    def sync_to(push)
      puts "* Pulling changes from origin master"
      chef_repo_cmd("git pull origin master")
      puts "* Checking out #{push['after']}"
      chef_repo_cmd("git checkout #{push['after']}")
      puts "* Updating Chef Server"
      modified_files = parse_commits( push['commits'] )
      puts "* Modified files: #{modified_files.join(', ')}"
      modified_files.each do |modified_file|
        chef_repo_cmd("/opt/chef/bin/knife upload -c " +
          "#{ENV['CHEF_REPO_DIR']}/.chef/knife.rb \"#{modified_file}\"")
      end
      puts "* Victory is yours."
    end
  end
end
