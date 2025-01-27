require "rmagick"

module Phash
  class Rmagick < Common
    def load_and_transform(file)
      orig = Magick::Image.read(file).first

      width  = orig.columns
      height = orig.rows

      # RMagick::QuantumRange is typically 65535 (for Q16 builds)
      quantum_max = Magick::QuantumRange.to_f  # 65535.0
      # This factor turns a 16-bit channel into [0..255], i.e. /257 approx
      scale_to_8  = quantum_max / 255.0

      gray = Magick::Image.new(width, height) do |image|
        image.depth = 16
        image.colorspace = Magick::GRAYColorspace
      end

      height.times do |y|
        row_in  = orig.get_pixels(0, y, width, 1)
        row_out = Array.new(width)

        row_in.each_with_index do |px, x|
          y_val_16 = y_from_rgb(px.red, px.green, px.blue, scale_to_8)
          row_out[x] = Magick::Pixel.new(y_val_16, y_val_16, y_val_16)
        end
        gray.store_pixels(0, y, width, 1, row_out)
      end

      kernel_7x7 = Array.new(7) { Array.new(7, 1.0) }

      img = gray.convolve(7, kernel_7x7.flatten)

      sample(img)
    end

    def y_from_rgb(r_16, g_16, b_16, scale_to_8)
      # Convert 16-bit channel values (0..65535) to approximate 8-bit (0..255)
      r8 = r_16 / scale_to_8
      g8 = g_16 / scale_to_8
      b8 = b_16 / scale_to_8

      # Apply the same formula: (66*r8 + 129*g8 + 25*b8 + 128)/256 + 16.5
      y_float = (66.0*r8 + 129.0*g8 + 25.0*b8 + 128.0)/256.0 + 16.5

      # Convert back to 16-bit scale
      y_float = (y_float * scale_to_8).round
      [[0, y_float].max, 65535].min
    end

    def sample(img)
      w, h = img.columns / 32.0, img.rows / 32.0
      Matrix.build(32, 32) do |dy, dx|
        py = (dy * h).floor
        px = (dx * w).floor
        img.pixel_color(px, py).red / CIMG_SCALE
      end
    end
  end
end
