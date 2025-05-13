require "zlib"
class Convert

  def self.parse_file
    path = png_path
    file = File.open(path)

    validate_png(file)

    # Extract width and color_type from image header
    width, color_type = read_image_header(file)
    inflated_data = inflate_chunks(file)

    # reconstruct scanlines by undoing the filter
    reconstruct_scanlines(inflated_data:, color_type:, width:)
    puts "done"
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


  # https://www.w3.org/TR/png/#9Filter-types
  # c b
  # a x
  def self.reconstruct_scanline(row:, bpp:, reconstructed_scanline:)
    bytes = row.bytes

    # first byte of the 'row' is the filter type (https://www.w3.org/TR/png/#7Filtering)
    filter_type = bytes.shift

    reconstructed_bytes = []
    bytes.map.with_index do |filt_x, index|
      puts reconstructed_bytes[index - bpp]
     reconstructed_byte = case filter_type
       # Filt(x)
       when 0
         filt_x
       # Filt(x) + Recon(a)
       when 1
         filt_x + (reconstructed_bytes[index - bpp] || 0)
       # Filt(x) + Recon(b)
       when 2
         filt_x
       when 3
         filt_x
       when 4
         filt_x
       end
        reconstructed_bytes <<  reconstructed_byte % 256
     end
   end

   def self.reconstruct_scanlines(inflated_data:, color_type:, width:)
     bpp = color_type == 2 ? 3 : 4
     #  type + data
     row_size = 1 + (width * bpp)

     reconstructed_scanlines = []
     reconstructed_scanline = nil

     (0...inflated_data.length).step(row_size).map do |offset|
       # the bytes for pixel information
       row = inflated_data[offset...(offset + row_size)]
       reconstructed_scanline = reconstruct_scanline(row:, bpp:, reconstructed_scanline:)
     end

   end

end

puts Convert.parse_file
