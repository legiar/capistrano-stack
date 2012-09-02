Capistrano::Configuration.instance(:must_exist).load do

  def _cset(name, *args, &block)
    unless exists?(name)
      set(name, *args, &block)
    end
  end

  # Check if remote file exists
  def remote_file_exists?(full_path)
    'true' ==  capture("if [ -e #{full_path} ]; then echo 'true'; fi").strip
  end

  # Check if process is running
  def remote_process_exists?(pid_file)
    capture("ps -p $(cat #{pid_file}) ; true").strip.split("\n").size == 2
  end

  def link_file(source_file, destination_file)
    if remote_file_exists?(source_file)
      run "#{try_sudo} ln -nsf #{source_file} #{destination_file}"
    end
  end

  def link_config_file(config_file, config_path = nil)
    config_path ||= File.join(release_path, "config")
    logger.important(config_path)
    link_file File.join(shared_path, "config", config_file),
              File.join(config_path, config_file)
  end

  def surun(command)
    password = fetch(:root_password, Capistrano::CLI.password_prompt("root password: "))
    run("su - -c '#{command}'") do |channel, stream, output|
      channel.send_data("#{password}n") if output
    end
  end

  _cset(:scm) { :git }
  _cset(:use_sudo) { false }
  _cset(:user) { "deployer" }

  namespace :stack do

    task :env do
      logger.debug("Application: #{application}")
      logger.debug("User: #{user}")
      logger.debug("SCM: #{scm}")
      logger.debug("Repository: #{repository}")
      logger.debug("Deploy path: #{deploy_to}")
      logger.debug("Use sudo: #{use_sudo}")
      logger.debug("Rails environment: #{rails_env}")
      #logger.debug("Keep releases: #{keep_releases}")
      logger.debug("Current path: #{current_path}")
    end

    namespace :server do
      desc "Initialize a fresh Linux install; create users, groups, upload pubkey, etc."
      task :prepare do
        #createuser -d -l -S -R webmaster
      end
    end

  end

end