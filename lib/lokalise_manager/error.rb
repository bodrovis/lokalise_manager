# frozen_string_literal: true

module LokaliseManager
  # The Error class provides a custom exception type for the LokaliseManager,
  # allowing the library to raise specific errors that can be easily identified
  # and handled separately from other StandardError exceptions in Ruby.
  class Error < StandardError
    # Initializes a new Error object
    def initialize(message = '')
      super
    end
  end
end
