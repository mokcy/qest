set :application, "mqtt-rest"
set :repository,  "gitolite@repo.matteocollina.com:mqtt-rest"

#set :scm, :subversion
set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

ip = "callisto.matteocollina.com"

role :web, ip 
role :app, ip
role :db, ip, :primary => true

set :user, "deploy"

set :use_sudo, false

set :app_port, 8000
set :mqtt_port, 8001

# support for github
ssh_options[:forward_agent] = true
set :git_enable_submodules, 1
set :deploy_via, :remote_cache

set :deploy_to, "/home/deploy/apps/#{application}"

# to avoid touching the public/javascripts public/images and public/stylesheets
set :normalize_asset_timestamps, false

$:.unshift(File.expand_path('./lib', ENV['rvm_path'])) # Add RVM's lib directory to the load path.
require "rvm/capistrano"                  # Load RVM's capistrano plugin.

set :forever_start do
  "cd #{current_path} && NODE_ENV=production forever start -p ~/forever app.js -p #{app_port} -m #{mqtt_port}"
end

namespace :deploy do
  task :start do
    run forever_start
  end

  task :stop do 
    run "cd #{current_path} && forever stop -p ~/forever app.js"
  end

  task :restart, :roles => :app, :except => { :no_release => true } do
    stop
    sleep 1
    start
  end

  task :migrate do
    # do nothing here!!
  end
end

namespace :dependencies do
  task :install do
    run "cd #{release_path} && npm install"
  end
end

task :start_on_boot do
  
    whenever_config= ERB.new <<-EOF
job_type :relative_command, "cd :path && :task :output"
set :output, "log/cron.log"

every :reboot do
  relative_command "#{forever_start}"
end
    EOF

    put whenever_config.result, "#{release_path}/config/schedule.rb" 
end

after "deploy:update_code", "dependencies:install"

require 'bundler/capistrano' # to use bundler

set :whenever_command, "bundle exec whenever"
require "whenever/capistrano"

before "whenever:update_crontab", "start_on_boot"