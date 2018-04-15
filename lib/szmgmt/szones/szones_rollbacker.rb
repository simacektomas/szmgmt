module SZMGMT
  module SZONES
    class SZONESRollbacker

      attr_reader :events_by_host

      def initialize
        @events_by_host = Hash.new { |h, k| h[k] = [] }
        @hosts_specs = {}
      end

      def add_zone_detach(zone_name, host_spec = {:host_name => 'localhost'})
        event = {
            :type => 'zone_detach',
            :data => {
                :zone_name => zone_name
            }
        }
        @events_by_host[host_spec[:host_name]] << event
        @hosts_specs[host_spec[:host_name]] ||= host_spec.to_h
      end

      def add_zone_halt(zone_name, host_spec = {:host_name => 'localhost'})
        event = {
          :type => 'zone_halt',
          :data => {
              :zone_name => zone_name
          }
        }
        @events_by_host[host_spec[:host_name]] << event
        @hosts_specs[host_spec[:host_name]] ||= host_spec.to_h
      end
      # Will iterate over events in reverse order and will
      # call rollback on each of events. Appropriate event
      # handler have to be implemented and follow naming
      # convetion
      def rollback!
        SZMGMT.logger.info("ROLLBACK: Initializing rollback of operations...")
        Parallel.each(@hosts_specs.keys, in_processes: @hosts_specs.keys.size ) do |host|
          @events_by_host[host].reverse_each do |event|
            SZMGMT.logger.info("ROLLBACK: Rollback of events on host #{host} has been initialized.")
            if host == 'localhost'
              self.send("#{event[:type]}_rollback", event[:data])
            else
              host_spec = @hosts_specs[host]
              Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec) do |ssh|
                self.send("#{event[:type]}_rollback", event[:data], ssh)
              end
            end
          end
        end
      end

      private

      # Event handler for rollbacking zone dettach
      def zone_detach_rollback(zone_detach, ssh = nil)
        begin
          attach = SZONESBasicZoneCommands.attach_zone(zone_detach[:zone_name])
          ssh ? attach.exec_ssh(ssh) : attach.exec
        rescue Exceptions::SZONESError
          SZMGMT.logger.warn("ROLLBACK: Cannot rollback detach of zone '#{zone_detach[:zone_name]}' (Cannot attach).")
        end
      end
      # Event handler for rollbacking zone halt
      def zone_halt_rollback(zone_halt, ssh = nil)
        begin
          boot = SZONESBasicZoneCommands.boot_zone(zone_halt[:zone_name])
          ssh ? boot.exec_ssh(ssh) : boot.exec
        rescue Exceptions::SZONESError
          SZMGMT.logger.warn("ROLLBACK: Cannot rollback zone '#{zone_halt[:zone_name]}' halt (Cannot boot).")
        end
      end
    end
  end
end