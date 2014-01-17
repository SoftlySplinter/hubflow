
module HubFlow
  module Commands
    instance_methods.each { |m| undef_method(m) unless m =~ /(^__|send|to\?$)/ }
    extend self
    extend Hub::Context

    def run(args)
      args.unshift 'help' if args.empty?
      cmd = args.shift
      
      if method_defined?(cmd) and cmd != 'run'
        send(cmd, args)
      end
    end

    def init(args)
      puts "$ flow init " << args.join(" ")
      default = args.delete('-d')
      force = args.delete('-f')
      create = args.delete('-c')

      puts "> git flow init " << (default ? '-d ' : '') << (force ? '-f ' : '')

      if not local_repo(false)
        puts "> hub init " << args.join(" ")
        Hub::Runner.new('init', hub_args)
      else
        if (not repo_is_headless?) or require_clean_working_tree?
          exit
        end
      end

      Hub::Runner.new('create') if not remote_repo_exists? and create
      
      if flow_initialised? and not force
        puts "Already initialized for gitflow."
        puts "To force reinitialization, use: git flow init -f"
        exit
      end

      puts "Using default branch names" if default

      master_branch

      master_branch = flow_master if flow_master_init? and not force
      
      default_suggestion = "master"
      should_check_existence = false
      
      if not branches?
        puts "No branches exist yes. Base branches must be created now."
        should_check_existence = false
        default_suggestion = flow_master || default_suggestion
      else
        puts "Which branch should be used for bringing forth production releases?"
        branches.each do |branch|
          puts "   - #{branch}"
        end
        should_check_existence = true
        default_suggestion = get_suggestion(flow_master, 'production', 'main', 'master') || 'master'
        
        print "Branch name for production releases: [#{default_suggestion}] "

        if default
          print "\n"
        else
          master_branch = STDIN.gets.chomp
        end

        master_branch = default_suggestion if (not master_branch) or master_branch.empty?

        if should_check_existence
          if not branches.include?(master_branch) and remote_branches.include?(master_branch)
            puts "> hub branch #{master_branch} origin/#{master_branch}"
            Hub::Runner.execute("branch", master_branch, "origin/#{master_branch}")
          elsif not branches.include?(master_branch)
            puts "Local branch '#{master_branch}' does not exist."
            exit
          end
        end
      end

      puts "> git config --add gitflow.branches.master #{master_branch}"
      git_command("config --add gitflow.branches.master #{master_branch}")
      
       
    end

    def get_suggestion(*suggested_branches)
      (branches & suggested_branches).first
    end

    def branches?
      not branches.empty?
    end

    def branches
      local_branches = []
      Dir.foreach(File.join(git_dir, "refs", "heads")) do |branch|
        next if branch.start_with?('.')
        local_branches << branch
      end
      return local_branches
    end

    def remote_branches
      remote_brchs = []
      Dir.foreach(File.join(git_dir, "refs", "remotes", "origin")) do |branch|
        next if branch.start_with?('.')
        remote_brchs << branch
      end
      return remote_brchs
    end

    def repo_is_headless?
      git_command('rev-parse --quiet --verify HEAD')
    end

    def is_clean_working_tree?
      if not git_command('diff --no-ext-diff --ignore-submodules --quiet --exit-code')
        return 1
      elsif not git_command('diff-index --cached --quiet --ignore-submodules HEAD --')
        return 2
      else
        return 0
      end
    end

    def require_clean_working_tree?
        res = is_clean_working_tree?
        if res > 0
          puts 'fatal: Working tree contains unstaged changes. Aborting.' if res == 1
          puts 'fatal: Index contains uncommited changes. Aborting.' if res == 2
          #exit
        end
        res == 0
    end

    def flow_initialised?
      flow_master_init? and flow_develop_init? and (flow_master != flow_develop) and flow_prefixes_configured?
    end

    def flow_master
      git_config("gitflow.branch.master")
    end

    def flow_develop
      git_config("gitflow.branch.develop")
    end

    def flow_master_init?
      flow_master and local_repo.file_exist?('refs', 'heads', flow_master)
    end

    def flow_develop_init?
      flow_develop and local_repo.file_exist?('refs', 'heads', flow_develop)
    end

    def flow_prefixes_configured?
      git_config("gitflow.prefix.feature") and
      git_config("gitflow.prefix.release") and 
      git_config("gitflow.prefix.hotfix") and 
      git_config("gitflow.prefix.support") 
      # Because of the way hub handles git config commands it will return nil 
      # if the result is empty or fails.
      # git_config("gitflow.prefix.versiontag")
    end

    def help(args)
      puts help_text
      exit
    end

    def help_text
      <<-help
useage: hubflow <command>

Available subcommands are:
    init      Initialize a new git repo with support for the branching model.
    feature   Manage your feature branches.
    release   Manage your release branches.
    hotfix    Manage your hotfix branches.
    support   Manage your support branches.
    version   Shows version information.

Try 'git flow <subcommand> help' for details.
      help
    end

  end
end
