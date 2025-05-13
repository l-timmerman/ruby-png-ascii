require "zlib"
class Convert

  def self.parse_file
    path = png_path
    file = File.open(path)

    validate_png(file)

    # Extract width and color_type from image header
    width, color_type = read_image_header(file)
    inflated_data = inflate_chunks(file)


    bpp = color_type == 2 ? 3 : 4
    row_size = 1 + (width * bpp)
    prev_scanline = nil
    prev_reconstructed_scanline = nil

    reconstructed_scanlines = []
    (0...inflated_data.length).step(row_size).each do |offset|

      # first byte of the 'row' is the filter type (https://www.w3.org/TR/png/#7Filtering)
      filter_type = inflated_data.getbyte(offset)
      # the bytes for pixel information
      scanline_bytes = inflated_data[(offset + 1)...(offset + row_size)].bytes


      # https://www.w3.org/TR/png/#9Filter-types
      # c b
      # a x
    recon_a = nil
     reconstructed_scanline = scanline_bytes.map.with_index do |filt_x, index|
        recon_a =
        case filter_type
        when 0
          filt_x
        when 1
          if index > 0 && recon_a
            # Filt(x) + Recon(a)
            filt_x + recon_a
          else
            filt_x
          end
        when 2
          # Filt(x) + Recon(b)
          filt_x
        when 3
          filt_x
        when 4
          filt_x
        end

        recon_a
      end
      prev_reconstructed_scanline = reconstructed_scanline
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
    # Not checking it for now
    _crc = file.read(4)
    [type, data]
  end

  # https://www.w3.org/TR/png/#11IHDR
  def self.read_image_header(file)
    type, data = read_chunk(file)
    if !type.eql?("IHDR")
      puts "Invalid image header: chunk type is #{type}, should be: IHDR"
      exit
    end
    width, height, bit_depth, color_type, comp, filter, interlace = data.unpack("NNCCCCC")

    puts "Width: #{width}"
    puts "Height: #{height}"
    puts "Bit depth: #{bit_depth}"
    puts "Color type: #{color_type}"
    puts "Compression: #{comp}"
    puts "Filter: #{filter}"
    puts "Interlace: #{interlace}"
    [width, color_type]
  end

  def self.inflate_chunks(file)
    encoded_data = ""
    while(!file.eof)
      type, data = read_chunk(file)
      if type.eql?("IDAT")
        encoded_data += data
      end
    end
    Zlib::Inflate.inflate(encoded_data)
  end

end

puts Convert.parse_file
