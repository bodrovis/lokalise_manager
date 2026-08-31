# frozen_string_literal: true

module LokaliseManager
  module Utils
    # Common helper methods for hashes
    module HashUtils
      refine Hash do
        # Deeply merges two hashes
        # Taken from https://api.rubyonrails.org/files/activesupport/lib/active_support/core_ext/hash/deep_merge_rb.html
        def deep_merge(other_hash, &block)
          dup.deep_merge!(other_hash, &block)
        end

        # Same as +deep_merge+, but modifies +self+.
        def deep_merge!(other_hash, &block)
          merge!(other_hash) do |key, this_val, other_val|
            if this_val.is_a?(Hash) && other_val.is_a?(Hash)
              this_val.deep_merge(other_val, &block)
            elsif block
              yield(key, this_val, other_val)
            else
              other_val
            end
          end
        end
      end
    end
  end
end
