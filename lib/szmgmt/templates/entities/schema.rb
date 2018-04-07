module SZMGMT
  module Templates
    module Entities
      class Schema
        attr_accessor :data, :path

        def initialize(data, path)
          @data = data
          @path = path
        end
      end
    end
  end
end
