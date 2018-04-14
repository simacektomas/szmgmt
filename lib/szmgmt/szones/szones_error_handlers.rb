module SZMGMT
  module SZONES
    module SZONESErrorHandlers

      def self.zoneadm_error_handler
        lambda { |command, stdout, stderr, exit_code|
         if exit_code > 0
          if /No such zone configured/.match(stderr)
            raise Exceptions::NoSuchZoneError.new(command, stderr)
          elsif /cannot manage a zone which is in state/.match(stderr) ||
                /must be installed before/.match(stderr)
            raise Exceptions::InvalidZoneStateError.new(command, stderr)
          end
         end
        }
      end

      def self.zonecfg_error_handler
        lambda { |command, stdout, stderr, exit_code|
          if exit_code > 0
            if /No such zone configured/.match(stderr)
              raise Exceptions::ZonecfgNoSuchZoneError.new(command, stderr)
            end
          end
        }
      end

      def self.zfs_error_handler
        lambda { |command, stdout, stderr, exit_code|
          if exit_code > 0
            if /filesystem does not exist/.match(stderr)
              raise Exceptions::ZFSNoSuchFilesystemError.new(command, stderr)
            elsif /No such file or directory/.match(stderr)
              raise Exceptions::ZFSNoSuchFileOrDirectoryError.new(command, stderr)
            end
          end
        }
      end

      def self.archiveadm_error_handler
        lambda { |command, stdout, stderr, exit_code|
          if exit_code > 0
            if /multiple zones not allowed for recovery archive/.match(stderr)
              raise Exceptions::CommandSyntaxError.new(command, stderr)
            elsif /Archive creation failed: zones not found/.match(stderr)
              raise Exceptions::NoSuchZoneError.new(command, stderr)
            end
          end
        }
      end

      def self.bash_error_handler
        lambda { |command, stdout, stderr, exit_code|
          if exit_code > 0
            if /Not a directory/.match(stderr)
              raise Exception::BashNotaDirectoryError.new(command, stderr)
            elsif /No such file or directory/.match(stderr)
              raise Exception::BashNoSuchFileorDirError.new(command, stderr)
            end
          end
        }
      end

      def self.basic_error_handler
        lambda { |command, stdout, stderr, exit_code|
          raise Exceptions::CommandFailureError.new(command, stderr, exit_code) if exit_code > 0
        }
      end
    end
  end
end