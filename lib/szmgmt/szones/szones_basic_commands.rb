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
      # Copy files to dest_dir. You can specify
      # multiple files to copy as well as directory
      # in which the files will be stored.
      def self.copy_files(paths_to_files, dest_dir)
        files = paths_to_files
        if paths_to_files.is_a? Array
          files = paths_to_files.join(' ')
        end
        Command.new("/usr/bin/cp #{files} #{dest_dir}",
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
      # Copy file from remote host over scp. You can specify
      # multiple files to copy as well as remote directory
      # in which the files will be stored.
      def self.copy_files_from_remote_host(paths_to_files, remote_host_spec, local_dir)
        files = paths_to_files
        if paths_to_files.is_a? Array
          tmp = []
          paths_to_files.each do |file|
            tmp << "#{remote_host_spec[:host_name]}:#{file}"
          end
          files = tmp.join(' ')
        else
          files = "#{remote_host_spec[:host_name]}:#{files}"
        end
        Command.new("/usr/bin/scp #{files} #{local_dir}",
                    SZONESErrorHandlers.bash_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Packup files to one archive using zip method. You
      # can specify junk_paths options to erase path from filenames
      # and store only the files
      def self.zip_files(path_to_archive, files, opts = {})
        junk_paths = opts[:junk_paths] || false
        Command.new("/usr/bin/zip #{"-j" if junk_paths} #{path_to_archive} #{files.join(' ')}",
                    SZONESErrorHandlers.bash_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Unpack files from archive using zip method to current dir. You
      # can specify output_dir options to extract files to defined
      # directory
      def self.unzip_archive(path_to_archive, opts = {})
        if opts[:output_dir]
          output_dir = "-d #{opts[:output_dir]}"
        else
          output_dir = ''
        end
        Command.new("/usr/bin/unzip #{path_to_archive} #{output_dir}",
                    SZONESErrorHandlers.bash_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
    end
  end
end