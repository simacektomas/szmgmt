module SZMGMT
  module SZONES
    class SZONESBasicZFSRoutines
      # If no compression type is recognized from file ending this
      # default compression is used
      @@default_compression = 'gzip'
      # Mapping between compression types and their ending in
      # file name
      @@compression_ends = {
          'gzip' => 'gz',
          'bzip2' => 'bz2'
      }
      # Create a volume of given name. Argument dataset_name
      # specify the place of new dataset/volume in the hierarchy
      # of ZFS datasets. Property path specify if the path of
      # non exsisting ZFS dataset should be created. Sparse option
      # specify if there should by any reservation for dataset.
      # Finally the properties options specify the properties
      # of the created dataset. See zfs(1).
      def self.create_dataset(dataset_name, opts = {})
        path = opts[:path] || false
        sparse = opts[:sparse] || false
        options = opts[:options] || {}
        properties = ''
        options.each do |property,value|
          properties << "-o #{property.to_s}=#{value.to_s}"
        end
        Command.new("/usr/sbin/zfs create #{"-p" if path} #{"-s" if sparse} #{properties} #{dataset_name}",
                    SZONESErrorHandlers.zfs_error_handler,
                    SZONESErrorHandlers.basic_error_handler)

      end
      # Destroys the given dataset if there is no other datasets that
      # actively depends on this dataset. You can user dependants option
      # to turn off this behaviour. Also you can specify if the children of
      # given dataset should be deleted as well. Last option force specify
      # if the dataset should be forcibly umounted.
      def self.destroy_dataset(dataset_name, opts = {})
        recursively = opts[:recursively] || false
        dependants = opts[:dependants] || false
        force = opts[:force] || false
        Command.new("/usr/sbin/zfs destroy #{"-r" if recursively} #{"-R" if dependants} #{"-f" if force} #{dataset_name}",
                    SZONESErrorHandlers.zfs_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Create a snapshot of given dataset with given snapshot_name.
      # You can specify recursive option to create snapshots of all
      # child of given dataset.
      def self.create_snapshot(dataset_name, snapshot_name, opts = {})
        recursive = opts[:recursive] || false
        Command.new("/usr/sbin/zfs snapshot #{"-r" if recursive} #{dataset_name}@#{snapshot_name}",
                    SZONESErrorHandlers.zfs_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Destroys the given snapshot if there is no other datasets or snapshots that
      # actively depends on this snapshot. You can user dependants option
      # to turn off this behaviour. Also you can specify recursive version
      # that deletes all snapshots with this name in hierarchy. Last option defer
      # specify if the act of destroying snapshots should be defer.
      def self.destroy_snapshot(snapshot_name, opts = {})
        recursively = opts[:recursively] || false
        dependants = opts[:dependants] || false
        defer = opts[:defer] || false
        Command.new("/usr/sbin/zfs destroy #{"-r" if recursively} #{"-R" if dependants} #{"-d" if defer} #{snapshot_name}",
                    SZONESErrorHandlers.zfs_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # It send ZFS dataset over ssh to another host. You can specify name of the new
      # dataset on new host using dest_dataset argument. You can also specify
      # if the dataset should be send with all children and if it should be
      # complete (don't depend on any other dataset).
      def self.send_dataset(dataset_name, host_name, dest_dataset, opts = {})
        complete = opts[:complete] || false
        recursive = opts[:recursive] || false
        Command.new("/usr/sbin/zfs send #{"-r" if recursive} #{"-c" if complete} #{dataset_name} | ssh #{host_name} /usr/sbin/zfs recv #{dest_dataset}",
                    SZONESErrorHandlers.zfs_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Archive dataset on current host under path_to_archive. Compression
      # type is determined from path_to_archive ending. Compression will
      # be used even if user will not specify the ending. You can also specify
      # if the dataset should be send with all childrens and if it should be
      # complete (don't depend on any other dataset).
      def self.archive_dataset(dataset_name, path_to_archive, opts = {})
        complete = opts[:complete] || false
        recursive = opts[:recursive] || false
        compression = @@default_compression
        @@compression_ends.each do |compres, ending|
          compression = compres if ending == path_to_archive.split('.').last
        end
        Command.new("/usr/sbin/zfs send #{"-r" if recursive} #{"-c" if complete} #{dataset_name} | #{compression} > #{path_to_archive}",
                    SZONESErrorHandlers.zfs_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
      # Archive dataset on remote host under path_to_archive. Compression
      # type is determined from path_to_archive ending. Compression will
      # be used even if user will not specify the ending. You can also specify
      # if the dataset should be send with all childrens and if it should be
      # complete (don't depend on any other dataset).
      def self.archive_dataset_on_remote(dataset_name, remote_path_to_archive, host_name, opts = {})
        complete = opts[:complete] || false
        recursive = opts[:recursive] || false
        compression = @@default_compression
        @@compression_ends.each do |compres, ending|
          compression = compres if ending == remote_path_to_archive.split('.').last
        end
        Command.new("/usr/sbin/zfs send #{"-r" if recursive} #{"-c" if complete} #{dataset_name} | #{compression} | ssh  #{host_name} \"cat > #{remote_path_to_archive}\"",
                    SZONESErrorHandlers.zfs_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end

      # List properties of datastets that meet the requirements.
      # You can specify header option to not print header of listed
      # information. Filter can be of type filesystem, volume, snapshot,
      # share or path. The properties array specify which properties to display.
      def self.list_properties(filter, properties = [], opts = {})
        header = opts[:header] || true
        props = properties.empty? ? '' : "-o #{properties.join(',')}"
        Command.new("/usr/sbin/zfs list #{"-H" if header} #{props} #{filter}",
                    SZONESErrorHandlers.zfs_error_handler,
                    SZONESErrorHandlers.basic_error_handler)
      end
    end
  end
end