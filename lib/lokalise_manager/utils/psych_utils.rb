module LokaliseManager
  module Utils
    # Common helper methods for psych
    module PsychUtils
      # :nocov:
      unless Psych.respond_to?(:safe_dump)
        refine Psych do
          def self.safe_dump(o, io = nil, options = {})
            if Hash === io
              options = io
              io      = nil
            end
        
            visitor = Psych::Visitors::RestrictedYAMLTree.create options
            visitor << o
            visitor.tree.yaml io, options
          end
        end
      end
      # :nocov:
    end
  end
end