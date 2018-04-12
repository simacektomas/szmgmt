module SZMGMT
  module SZONES
    class Command

      attr_reader :command, :stdout, :stderr, :exit_code, :executed

      def initialize(command)
        @command = command
        @stdout = ''
        @stderr = ''
        @exit_code = false
        @executed = false
        @sucess = true
        @error_handler = lambda { |command, stdout, stderr, exit_code|
          raise Exceptions::CommandFailure.new(command,exit_code) if exit_code > 0
        }
      end

      def exec
        @stdout, @stderr, exit_code  = Open3.capture3(@command)
        @exit_code = exit_code.exitstatus
        @error_handler.call(@command ,@stdout, @stderr, @exit_code)
        @executed = true
        self
      end

      def exec_ssh(ssh)
        ssh.open_channel do |channel|
          channel.exec(@command) do |ch, success|
            raise StandardError unless success

            channel.on_data do |ch,data|
              @stdout += data
            end

            channel.on_extended_data do |ch,type,data|
              @stderr += data
            end

            channel.on_request("exit-status") do |ch,data|
              @exit_code = data.read_long
            end
          end
        end
        ssh.loop
        @error_handler.call(@command ,@stdout, @stderr, @exit_code)
        @executed = true
        self
      end

      def register_error_handler(handler)
        @error_handler = handler
      end
    end
  end
end