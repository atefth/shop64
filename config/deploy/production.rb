set :stage, :production
set :rails_env, :production
set :deploy_to, "/home/ec2-user/apps/#{fetch(:application)}"
set :branch, 'master'

set :puma_user, fetch(:user)
set :puma_rackup, -> { File.join(current_path, "config.ru") }
set :puma_state, "#{shared_path}/tmp/pids/puma.state"
set :puma_pid, "#{shared_path}/tmp/pids/puma.pid"
set :puma_bind, "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_conf, "#{shared_path}/puma.rb"
set :puma_access_log, "#{release_path}/log/puma.error.log"
set :puma_error_log, "#{release_path}/log/puma.access.log"
set :puma_env, fetch(:rack_env, fetch(:rails_env, "production"))
set :puma_threads, [2, 16]
set :puma_workers, 2
set :puma_restart_command, "bundle exec puma"

server '54.169.117.75',
       user: 'ec2-user',
       roles: %w{web app db},
       ssh_options: {
           keys: %w(~/.ssh/id_rsa),
           forward_agent: true,
           auth_methods: %w(publickey)
       }
