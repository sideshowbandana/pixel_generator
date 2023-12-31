require 'json'
require "pry-byebug"
require 'chunky_png'

class PixelDataConverter
  # Define a mapping of color names to binary representations
  COLOR_MAPPING = {
    black: '000',
    red: '100',
    magenta: '101',
    yellow: '110',
    green: '010',
    cyan: '011',
    blue: '001',
    white: '111'
  }

  HEX_MAPPING = {
    black: 0x000,
    red: 0xF00,
    green: 0x0F0,
    blue: 0x00F,
    white: 0xFFF,
    yellow: 0xFF0,
    magenta: 0xF0F,
    cyan: 0x0FF
  }

  def initialize
    @pixel_data = ''
  end

  def generate_from_color_matrix(color_matrix)
    pixel_array = ["", "", ""]
    color_matrix.each do |color|
      c = COLOR_MAPPING[color]
      3.times do |idx|
        pixel_array[idx] << c[idx]
      end
    end
    to_json(pixel_array)
  end

  # Method to convert pixel data array to JSON output
  def to_json(pixel_data_array)
    @pixel_data = pixel_data_array.join('')

    byte_array = @pixel_data.scan(/.{8}/).map { |byte| byte.to_i(2) }

    json_blob = {
      "data": {
        "speed": 247,
        "mode": 1,
        "pixelHeight": 16,
        "stayTime": 2,
        "graffitiData": byte_array, # Place the byte array here
        "pixelWidth": 64,
        "graffitiType": 1
      },
      "dataType": 1
    }

    JSON.generate([json_blob])
  end

  # Method to convert JSON output to pixel data array
  def from_json(json_string)
    json_data = JSON.parse(json_string)
    graffiti_data = json_data[0]["data"]["graffitiData"]

    @pixel_data = graffiti_data.map { |byte| byte.to_s(2).rjust(8, '0') }.join('')

    @pixel_data.chars.map(&:to_i)
  end

  def generate_from_image(image_path)
    pixel_array = []

    image = ChunkyPNG::Image.from_file(image_path)
    width, height = image.width, image.height
    (0...64).each do |x|
      (0...16).each do |y|
        if height <= y || width <= x
          pixel_array << :black
        else
          pixel_color = image[x, y]
          closest_color = find_closest_color(pixel_color)
          pixel_array << closest_color
        end
      end
    end
    generate_from_color_matrix(pixel_array)
  end

  private

  # Method to find the closest color from the predefined color palette
  def find_closest_color(pixel_color)
    min_distance = Float::INFINITY
    closest_color = nil

    COLOR_MAPPING.each do |color_name, color_value|
      color_rgb = HEX_MAPPING[color_name].to_i
      distance = euclidean_distance(pixel_color, color_rgb)
      if distance < min_distance
        min_distance = distance
        closest_color = color_name
      end
    end

    closest_color
  end

  # Method to calculate Euclidean distance between two colors
  def euclidean_distance(color1, color2)
    Math.sqrt((ChunkyPNG::Color.r(color1) - ChunkyPNG::Color.r(color2))**2 + (ChunkyPNG::Color.g(color1) - ChunkyPNG::Color.g(color2))**2 + (ChunkyPNG::Color.b(color1) - ChunkyPNG::Color.b(color2))**2)
  end
end

# Example usage:

# Create an instance of the PixelDataConverter class
converter = PixelDataConverter.new

File.open("output.jt", "wb") do |f|
  # f.puts converter.generate_from_color_matrix(16.times.map{ :white } + 16.times.map{ :blue } + (1024-32).times.map{ :black })
  f.puts converter.generate_from_image(ARGV[0])
end
