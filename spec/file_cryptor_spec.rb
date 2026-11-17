# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require_relative "../lib/file_cryptor"

RSpec.describe FileCryptor::Encryptor do
  let(:temp_dir) { Dir.mktmpdir }
  let(:plain_path) { File.join(temp_dir, "message.txt") }
  let(:plain_content) { "Secret message at #{Time.now}" }

  before do
    # Write a temporary plaintext file.
    File.write(plain_path, plain_content)

    # Ensure a deterministic key for tests.
    ENV["ENCRYPTION_KEY"] = Base64.strict_encode64("a" * 32)
    ENV["LOG_LEVEL"] = "error"
    FileCryptor::Config.load!
  end

  after { FileUtils.remove_entry(temp_dir) }

  it "encrypts and decrypts a file correctly" do
    encrypted_path = described_class.encrypt(plain_path)
    expect(File).to exist(encrypted_path)

    decrypted_path = described_class.decrypt(encrypted_path)
    expect(File).to exist(decrypted_path)

    decrypted_content = File.read(decrypted_path)
    expect(decrypted_content).to eq(plain_content)
  end

  it "raises an error when decrypting with a wrong key" do
    encrypted_path = described_class.encrypt(plain_path)

    # Change the key to something else.
    ENV["ENCRYPTION_KEY"] = Base64.strict_encode64("b" * 32)
    FileCryptor::Config.load!

    expect {
      described_class.decrypt(encrypted_path)
    }.to raise_error(RuntimeError, /Authentication failed/)
  end
end