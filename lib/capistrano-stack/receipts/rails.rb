Capistrano::Configuration.instance(:must_exist).load do

  if fetch(:deploy_to) == "/u/apps/#{application}"
    set(:deploy_to) do 
      ["/home/#{user}/#{application}", fetch(:stage, nil)].compact.join("/")
    end
  end

  namespace :deploy do

    desc "Create shared dirs"
    task :setup_shared_dirs, :roles => :app do
      dirs = [File.join(shared_path, "config")]
      dirs << fetch(:shared_folders, []).map{ |d| File.join(shared_path, d.split('/').last) }
      run "#{try_sudo} mkdir -p #{dirs.join(" ")}"
      run "#{try_sudo} chmod g+w #{dirs.join(" ")}" if fetch(:group_writable, true)
    end

    namespace :config do

      desc "Create config symlink"
      task :symlink do
        files = %w(database.yml)
        files << fetch(:configuraon_files, [])
        files.flatten.compact.each do |file|
          link_config_file(file)
        end
      end
    end

  end

  after "deploy:setup", "deploy:setup_shared_dirs"

  before "deploy:finalize_update", "deploy:config:symlink"
  after "deploy:update", "deploy:cleanup"
end