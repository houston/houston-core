require "thor"

module Houston
  class CLI < Thor

    desc "new NAME", "Generate a new instance of Houston or module"
    option :module, type: :boolean, desc: "Generate a new module"
    def new(name)
      if options[:module]
        require "generators/module_generator"
        Generators::ModuleGenerator.start(args)
      else
        require "generators/instance_generator"
        Generators::InstanceGenerator.start(args)
      end
    end

  end
end
