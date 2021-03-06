# frozen_string_literal: true

module LokaliseManager
  # LokaliseManager error class, subclass of StandardError
  class Error < StandardError
    # Initializes a new Error object
    def initialize(message = '')
      super(message)
    end
  end
end
