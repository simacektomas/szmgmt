module SZMGMT
  module SZONES
    class Command

      attr_reader :command, :stdout, :stderr, :exit_code, :executed

      def initialize(command, *error_handlers)
        @command = command
        @stdout = ''
        @stderr = ''
        @exit_code = false
        @executed = false
        @sucess = true
        @error_handlers = [SZONESErrorHandlers.basic_error_handler]
        @error_handlers = error_handlers unless error_handlers.empty?
      end

      def exec
        SZMGMT.logger.debug("Command - #{command} executed.")
        @stdout, @stderr, exit_code  = Open3.capture3(@command)
        @exit_code = exit_code.exitstatus
        @error_handlers.each do |handler|
          handler.call(@command ,@stdout, @stderr, @exit_code)
        end
        @executed = true
        self
      end

      def exec_ssh(ssh)
        SZMGMT.logger.debug("Command - #{command} remotely executed.")
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
        ssh.loop { ssh.busy? }
        @error_handlers.each do |handler|
          handler.call(@command ,@stdout, @stderr, @exit_code)
        end
        @executed = true
        self
      end

      def register_error_handler(handler)
        @error_handlers << handler
      end
    end
  end
end