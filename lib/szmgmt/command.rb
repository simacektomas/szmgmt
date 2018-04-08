module SZMGMT
  class Command

    attr_reader :stdout, :stderr, :exit_code, :executed

    def initialize(command)
      @command = command
      @stdout, @stderr = ''
      @exit_code = nil
      @executed = false
    end

    def exec
      @stdout, @stderr, @exit_code  = Open3.capture3(@command)
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
      @executed = true
      self
    end
  end
end