set :stages, %w(development staging production )
set :default_stage, "production"

set :application, fetch(:application) || "shop64.co"
set :user, fetch(:user) || "ec2-user"
set :repo_url, "git@github.com:atefth/shop64.git"

set :keep_releases, 2

ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# set :linked_files, fetch(:linked_files, []).push("config/database.yml", "config/secrets.yml")
# set :linked_dirs, %w(tmp/pids tmp/sockets log)

# set :assets_roles, [:assets]

set :pty, true
set :use_sudo, false
set :deploy_via, :remote_cache
set :deploy_to, fetch(:deploy_to) || "/home/#{fetch(:user)}/apps/#{fetch(:application)}"

set :rbenv_type, :user
set :rbenv_ruby, File.read(".ruby-version").strip
set :rbenv_prefix, "#{fetch(:rbenv_path)}/bin/rbenv exec"
# set :rbenv_prefix, "RBENV_ROOT=#{fetch(:rbenv_path)} RBENV_VERSION=#{fetch(:rbenv_ruby)} #{fetch(:rbenv_path)}/bin/rbenv exec"
set :rbenv_map_bins, %w{rake gem bundle ruby rails}
set :rbenv_roles, :all

# set :bundle_gemfile, "#{current_path}/Gemfile"
# set :bundle_path, "#{shared_path}/.bundle"

set :bundle_path, "#{fetch(:rbenv_path)}/versions/#{fetch(:rbenv_ruby)}/lib/ruby/gems/#{fetch(:rbenv_ruby)}"
set :bundle_path, "#{fetch(:rbenv_path)}/versions/#{fetch(:rbenv_ruby)}/lib/ruby/gems/2.5.0" if fetch(:rbenv_ruby).eql?("2.5.1")
set :bundle_without, %w{development test}.join(" ")
set :bundle_flags, "--deployment --quiet"

namespace :puma do
  desc "Create Directories for Puma Pids and Socket"
  task :make_dirs do
    on roles(:app) do
      execute "mkdir #{shared_path}/tmp/sockets -p"
      execute "mkdir #{shared_path}/tmp/pids -p"
    end
  end
  before :start, :make_dirs
end

def invoke!(task, *args)
  Rake::Task[task].reenable
  invoke(task, *args)
end

def context(**args)
  settings = %w[rails_env path user].map!(&:to_sym)
  settings.each do |setting|
    unless args[setting].nil?
      case setting
      when :path
        within(send(args[setting])) do
          yield
        end
      when :rails_env
        with(args[setting]) do
          yield
        end
      when :user
        as(args[setting]) do
          yield
        end
      end
    end
  end
end

def run_command(**args)
  on release_roles([args[:roles]]) do |host|
    context(args) do
      execute args[:command]
    end
  end
end

namespace :assets do
  desc "Install yarn dependencies"
  task :yarn do
    run_command(path: "current_path", command: "yarn install --silent")
  end

  desc "Clean assets"
  task :clean do
    run_command(path: "current_path", command: "cd #{current_path} && rails assets:clean")
  end
end

namespace :db do
  desc "Drop database"
  task :drop, :args do |t, args|
    run_command(path: "current_path", roles: :db, command: "cd #{current_path} && rails db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=1", **args)
  end

  desc "Create database"
  task :create, :args do |t, args|
    run_command(path: "current_path", roles: :db, command: "cd #{current_path} && rails db:create", **args)
  end

  desc "Migrate database"
  task :migrate, :args do |t, args|
    run_command(path: "current_path", roles: :db, command: "cd #{current_path} && rails db:migrate", **args)
  end

  desc "Refresh database"
  task :refresh do
    invoke "db:drop"
    invoke "db:create"
    invoke "db:migrate"
  end

  desc "Reset database"
  task :reset do
    invoke "db:refresh"
    invoke "db:seed:all"
  end

  namespace :seed do
    desc "Seed default data"
    task :default, :args do |t, args|
      run_command(path: "current_path", roles: :db, command: "cd #{current_path} && rails db:seed", **args)
    end

    desc "Seed users"
    task :users, :args do |t, args|
      run_command(path: "current_path", roles: :db, command: "cd #{current_path} && rails db:seed:sbc_users", **args)
    end

    desc "Seed document types"
    task :document_types, :args do |t, args|
      run_command(path: "current_path", roles: :db, command: "cd #{current_path} && rails db:seed:sbc_document_types", **args)
    end

    desc "Seed insitution"
    task :institution, :args do |t, args|
      run_command(path: "current_path", roles: :db, command: "cd #{current_path} && rails db:seed:sbc_institution", **args)
    end

    desc "All"
    task :all do
      invoke "db:seed:default"
      invoke "db:seed:users"
      invoke "db:seed:document_types"
      invoke "db:seed:institution"
    end
  end
end