# frozen_string_literal: true

# Taken from https://github.com/rails/rails/blob/6bfc637659248df5d6719a86d2981b52662d9b50/activesupport/lib/active_support/core_ext/array/grouping.rb

module LokaliseManager
  module Utils
    module ArrayUtils
      refine Array do
        def in_groups_of(number, fill_with = nil, &block)
          if number.to_i <= 0
            raise ArgumentError,
                  "Group size must be a positive integer, was #{number.inspect}"
          end

          if fill_with == false
            collection = self
          else
            padding = (number - (size % number)) % number
            collection = dup.concat(Array.new(padding, fill_with))
          end

          collection.each_slice(number, &block)
        end
      end
    end
  end
end
