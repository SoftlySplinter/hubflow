
module HubFlow
  module Commands
    instance_methods.each { |m| undef_method(m) unless m =~ /(^__|send|to\?$)/ }
    extend self
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

      if not Hub::Commands.send(:local_repo, false)
        puts "> hub init " << args.join(" ")
        Hub::Runner.new('init', hub_args)
      end
      

      if flow_initialised? and not force
        puts "Already initialized for gitflow."
        puts "To force reinitialization, use: git flow init -f"
        exit 0
      end
      puts "> git flow init " << (default ? '-d ' : '') << (force ? '-f ' : '')
    end

    def flow_initialised?
      flow_master_init? and flow_develop_init? and (flow_master != flow_develop) and flow_prefixes_configured?
    end

    def flow_master_init?
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
