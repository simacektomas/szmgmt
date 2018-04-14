module SZMGMT
  module SZONES
    class SZONESBasicCommands
      # Basic bash command for remove file. You can sepcify
      # recursive option along with force option.
      def self.remove_file(path_to_file, opts = {})
        recursive = opts[:recursive] || false
        force = opts[:force] || false
        Command.new("/usr/bin/rm #{"-r" if recursive} #{"-f" if force} #{path_to_file}",
                    SZONESErrorHandlers.bash_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
    end
  end
end