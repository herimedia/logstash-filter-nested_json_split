#!/usr/bin/env ruby

require "digest/sha2"

Dir["pkg/*.gem"].each do |f|
  checksum_file = "checksums/#{File.basename(f)}.sha512"
  next if File.exists?(checksum_file)

  File.write(checksum_file, Digest::SHA512.new.hexdigest(File.read(f)))
end
