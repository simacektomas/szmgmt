module SZMGMT
  class SSHSession

    attr_reader :conn_spec, :commands

    def initialize(ssh_connection_spec)
      @conn_spec = ssh_connection_spec
      @commands = []
    end

    def add_command(command)
      @commands << command
      self
    end

    def run
      Net::SSH.start(@conn_spec[:host_name], @conn_spec[:user], @conn_spec) do |ssh|
        @commands.each do |command|
          command.exec_ssh(ssh)
          #break if command.exit_code != 0 || (not command.stderr.empty?)
        end
      end
    end
  end
end