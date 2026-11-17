# frozen_string_literal: true

require "openssl"
require "securerandom"
require_relative "config"
require_relative "logger"

module FileCryptor
  # Provides AES‑256‑GCM encryption and decryption utilities.
  class Encryptor
    # Public: Encrypts the given file.
    #
    # input_path - String path to the plaintext file.
    #
    # Returns String path to the encrypted file (input_path + ".enc").
    # Raises RuntimeError on failure.
    def self.encrypt(input_path)
      raise "File not found: #{input_path}" unless File.file?(input_path)

      cipher = OpenSSL::Cipher.new(Config.cipher_name)
      cipher.encrypt
      cipher.key = Config.encryption_key
      iv = SecureRandom.random_bytes(cipher.iv_len)
      cipher.iv = iv

      plaintext = File.binread(input_path)
      encrypted = cipher.update(plaintext) + cipher.final
      auth_tag = cipher.auth_tag
# minor polish

      out_path = "#{input_path}.enc"
      File.open(out_path, "wb") do |f|
        # Store iv length (1 byte), iv, auth_tag length (1 byte), auth_tag, then ciphertext.
        f.write([iv.bytesize].pack("C"))
        f.write(iv)
        f.write([auth_tag.bytesize].pack("C"))
        f.write(auth_tag)
        f.write(encrypted)
      end

      Logger.info("File encrypted", input: input_path, output: out_path)
      out_path
    rescue => e
      Logger.error("Encryption failed", file: input_path, error: e.message)
      raise
    end

    # Public: Decrypts the given encrypted file.
    #
    # encrypted_path - String path to the .enc file.
    #
    # Returns String path to the decrypted file (original name without .enc).
    # Raises RuntimeError on failure.
    def self.decrypt(encrypted_path)
      raise "File not found: #{encrypted_path}" unless File.file?(encrypted_path)

      data = File.binread(encrypted_path)
      io = StringIO.new(data)

      iv_len = io.read(1).unpack1("C")
      iv = io.read(iv_len)
      tag_len = io.read(1).unpack1("C")
      auth_tag = io.read(tag_len)
      ciphertext = io.read

      cipher = OpenSSL::Cipher.new(Config.cipher_name)
      cipher.decrypt
      cipher.key = Config.encryption_key
      cipher.iv = iv
      cipher.auth_tag = auth_tag

      plaintext = cipher.update(ciphertext) + cipher.final

      out_path = encrypted_path.sub(/\.enc\z/, "")
      File.binwrite(out_path, plaintext)

      Logger.info("File decrypted", input: encrypted_path, output: out_path)
      out_path
    rescue OpenSSL::Cipher::CipherError => e
      Logger.error("Decryption failed – authentication error", file: encrypted_path, error: e.message)
      raise "Authentication failed – the file may be tampered or the key is wrong."
    rescue => e
      Logger.error("Decryption failed", file: encrypted_path, error: e.message)
      raise
    end
  end
end