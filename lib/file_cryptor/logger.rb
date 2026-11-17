# frozen_string_literal: true

require "logger"
require "json"

module FileCryptor
  # Simple JSON logger wrapper.
  module Logger
    class << self
      # Initializes the logger with the desired level.
      #
      # level - Symbol (:debug, :info, :warn, :error, :fatal)
      def init!(level = :info)
        @logger = ::Logger.new($stdout)
        @logger.level = level
        @logger.formatter = proc do |severity, datetime, _progname, msg|
          {
            timestamp: datetime.utc.iso8601,
            level: severity,
            message: msg
          }.to_json + "\n"
        end
      end

      # Generic log method.
      def log(severity, message, **metadata)
        @logger.send(severity, format_message(message, metadata))
      end

      # Shortcut methods.
      %i[debug info warn error fatal].each do |lvl|
        define_method(lvl) do |msg, **meta|
          log(lvl, msg, **meta)
        end
      end

      private

      def format_message(msg, meta)
        return msg if meta.empty?

        "#{msg} | #{meta.map { |k, v| "#{k}=#{v}" }.join(' ')}"
      end
    end
  end
end