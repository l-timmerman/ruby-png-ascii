class Convert

  def self.parse_file
    path = png_path

    File.open(path) do |file|
      validate_png(file)
    end
  end

  private

  def self.png_path
    png_path = nil

    ARGV.each do |arg|
      if arg.start_with?('--png_path=')
        png_path = arg.split('=', 2)[1]
      end
    end

    if png_path.nil?
      puts "Usage: ruby convert.rb --png_path=yourfile.png"
      exit
    end

    png_path
  end

  def self.validate_png(file)
    # https://www.w3.org/TR/png/#3PNGsignature
    hex_png_signature = "89 50 4E 47 0D 0A 1A 0A".split.map { |hex| hex.to_i(16) }
    return if file.read(8).bytes == hex_png_signature

    puts "Invalid PNG signature"
    exit
  end


  # https://www.w3.org/TR/png/#5Chunk-layout
  def self.read_chunk(file)
    # unsigned integer big endian
    length = file.read(4).unpack1("N")
    type = file.read(4)
    data = file.read(length)
    # Not using it for now
    crc = file.read(4)
    [type, data]
  end
end

puts Convert.parse_file
