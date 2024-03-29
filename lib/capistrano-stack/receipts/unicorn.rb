Capistrano::Configuration.instance(:must_exist).load do

  # Get unicorn master process PID
  def unicorn_get_pid(pid_file=unicorn_pid)
    if remote_file_exists?(pid_file) && remote_process_exists?(pid_file)
      capture("cat #{pid_file}")
    end
  end

  # Get unicorn master (old) process PID
  def unicorn_get_oldbin_pid
    oldbin_pid_file = "#{unicorn_pid}.oldbin"
    unicorn_get_pid(oldbin_pid_file)
  end

  # Send a signal to unicorn master process
  def unicorn_send_signal(pid, signal)
    run "#{try_sudo} kill -s #{signal} #{pid}"
  end

  # Set unicorn vars
  before ['unicorn:start', 'unicorn:stop', 'unicorn:shutdown', 
          'unicorn:restart', 'unicorn:reload', 'unicorn:add_worker',  
          'unicorn:remove_worker'] do
    _cset(:unicorn_pid) { "#{fetch(:shared_path)}/pids/unicorn.pid" }
    _cset(:app_env) { (fetch(:rails_env) rescue 'production') }
    _cset(:unicorn_env) { fetch(:app_env) }
    _cset(:unicorn_bin, "unicorn")
  end

  # Unicorn rake tasks
  namespace :unicorn do
    desc "Start Unicorn master process"
    task :start, :roles => :app, :except => {:no_release => true} do
      if remote_file_exists?(unicorn_pid)
        if remote_process_exists?(unicorn_pid)
          logger.important("Unicorn is already running!", "Unicorn")
          next
        else
          run "rm #{unicorn_pid}"
        end
      end

      primary_config_path = "#{current_path}/config/unicorn.rb"
      if remote_file_exists?(primary_config_path)
        config_path = primary_config_path
      else
        config_path = "#{current_path}/config/unicorn/#{unicorn_env}.rb"
      end

      if remote_file_exists?(config_path)
        logger.important("Starting...", "Unicorn")
        run "cd #{current_path} && BUNDLE_GEMFILE=#{current_path}/Gemfile bundle exec #{unicorn_bin} -c #{config_path} -E #{app_env} -D"
      else
        logger.important("Config file for \"#{unicorn_env}\" environment was not found at \"#{config_path}\"", "Unicorn")
      end
    end

    desc "Stop Unicorn"
    task :stop, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Stopping...", "Unicorn")
        unicorn_send_signal(pid, "QUIT")
      else
        logger.important("Unicorn is not running.", "Unicorn")
      end
    end

    desc "Immediately shutdown Unicorn"
    task :shutdown, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Stopping...", "Unicorn")
        unicorn_send_signal(pid, "TERM")
      else
        logger.important("Unicorn is not running.", "Unicorn")
      end
    end

    desc "Restart Unicorn"
    task :restart, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Restarting...", "Unicorn")
        unicorn_send_signal(pid, 'USR2')
        newpid = unicorn_get_pid
        oldpid = unicorn_get_oldbin_pid
        unless oldpid.nil?
          logger.important("Quiting old master...", "Unicorn")
          unicorn_send_signal(oldpid, 'QUIT')
        end
      else
        unicorn.start
      end
    end

    desc "Reload Unicorn"
    task :reload, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Reloading...", "Unicorn")
        unicorn_send_signal(pid, 'HUP')
      else
        unicorn.start
      end
    end

    desc "Add a new worker"
    task :add_worker, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Adding a new worker...", "Unicorn")
        unicorn_send_signal(pid, "TTIN")
      else
        logger.important("Server is not running.", "Unicorn")
      end
    end

    desc "Remove amount of workers"
    task :remove_worker, :roles => :app, :except => {:no_release => true} do
      pid = unicorn_get_pid
      unless pid.nil?
        logger.important("Removing worker...", "Unicorn")
        unicorn_send_signal(pid, "TTOU")
      else
        logger.important("Server is not running.", "Unicorn")
      end
    end
  end

  #after "deploy:restart", "unicorn:restart"
end
