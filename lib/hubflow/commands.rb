
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

      if not local_repo(false)
        puts "> hub init " << args.join(" ")
        Hub::Runner.new('init', hub_args)
      else
        if (not repo_is_headless?) or require_clean_working_tree?
          puts "Repository is not headless"
          exit 0
        end
      end
      
      if flow_initialised? and not force
        puts "Already initialized for gitflow."
        puts "To force reinitialization, use: git flow init -f"
        exit
      end

      puts "> git flow init " << (default ? '-d ' : '') << (force ? '-f ' : '')
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
          exit
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

Basic Commands:
    init    Create an empty git repository with gitflow information or 
            reinitialise an existing one.
      help
    end

  end
end
