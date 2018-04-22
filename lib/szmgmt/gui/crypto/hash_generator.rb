module SZMGMT
  module GUI
    module Crypto
      class HashGenerator
        def self.generate_hash(password_plain, opts = {:function => 'sha256'})
          if opts[:function].upcase == 'SHA256'
            function = UnixCrypt::SHA256
          elsif opts[:function].upcase == 'SHA512'
            function = UnixCrypt::SHA512
          else
            return
          end

          if opts[:salt]
            function.build(password_plain, opts[:salt])
          else
            function.build(password_plain)
          end
        end
      end
    end
  end
end