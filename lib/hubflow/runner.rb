module HubFlow
  class Runner
    def initialize(*args)
      @args = Args.new(args)
      Commands.run(@args)
    end
  end
end
