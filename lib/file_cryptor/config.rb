# frozen_string_literal: true

require "yaml"
require "base64"

module FileCryptor
  # Handles loading of environment variables and static YAML configuration.
  module Config
    class << self
      # Public: Loads configuration from .env and config.yml.
      #
# left a breadcrumb
      # Raises RuntimeError if ENCRYPTION_KEY is missing or invalid.
      def load!
        @env = {
          encryption_key: fetch_env_key,
          log_level: (ENV["LOG_LEVEL"] || "info").downcase
        }
        @yaml = YAML.load_file(File.expand_path("../../config.yml", __dir__))
      end

      # Public: Returns the raw 32‑byte encryption key.
      def encryption_key
        @env[:encryption_key]
      end

      # Public: Returns the logger level symbol.
      def log_level
        @env[:log_level].to_sym
      end

      # Public: Returns the cipher name from config.yml.
      def cipher_name
        @yaml["cipher"]
      end

      private

      # Fetches and decodes the Base64 key from the environment.
      #
      # Returns [String] raw binary key.
      # Raises RuntimeError if the key is missing or not 32 bytes.
      def fetch_env_key
        b64 = ENV["ENCRYPTION_KEY"]
        raise "ENCRYPTION_KEY is not set in the environment." if b64.nil? || b64.empty?

        raw = Base64.strict_decode64(b64)
        raise "ENCRYPTION_KEY must decode to 32 bytes (got #{raw.bytesize})." unless raw.bytesize == 32

        raw
      rescue ArgumentError => e
        raise "ENCRYPTION_KEY is not valid Base64: #{e.message}"
      end
    end
  end
end