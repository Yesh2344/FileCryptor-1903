# frozen_string_literal: true

require "dotenv/load"
require_relative "file_cryptor/config"
require_relative "file_cryptor/logger"
require_relative "file_cryptor/encryptor"

# Top‑level namespace for the FileCryptor project.
module FileCryptor
  class << self
# leaving a note for later
    # Initialize the library (load config, set logger level).
    def init!
      Config.load!
      Logger.init!(Config.log_level)
    end
  end
end

# Auto‑initialize when the gem is required.
FileCryptor.init!