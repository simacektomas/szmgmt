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

      # Copy file to remote host over scp. You can specify
      # multiple files to copy as well as remote directory
      # in which the files will be stored.
      def self.copy_files_on_remote_host(paths_to_files, remote_host_spec, remote_dir)
        files = paths_to_files
        if paths_to_files.is_a? Array
          files = paths_to_files.join(' ')
        end
        Command.new("/usr/bin/scp #{files} #{remote_host_spec[:host_name]}:#{remote_dir}",
                    SZONESErrorHandlers.bash_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
    end
  end
end