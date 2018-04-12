module SZMGMT
  module SZONES
    class CommandExecutor
      attr_reader :commands

      def initialize
        @commands = []
      end

      def reset
        @commands = []
      end

      def add_command(command)
        raise ArgumentError 'Not instance of Command class' unless command.is_a? SZMGMT::Command
        @commands << command
        self
      end

      def add_commands(commands)
        commands.each do |command|
          raise ArgumentError 'Not instance of Command class' unless command.is_a? SZMGMT::Command
          @commands << command
        end
        self
      end

      def execute
        @commands.each do |command|
          command.exec
        end
      end

      def remote_ssh_execute(host_spec)
        Net::SSH.start(host_spec[:host_name], host_spec[:user], host_spec) do |ssh|
          @commands.each do |command|
            command.exec_ssh(ssh)
          end
        end
      end
    end
  end
end