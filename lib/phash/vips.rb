require "vips"
require "matrix"

module Phash
  class Vips < Common
    def load_and_transform(file)
      img = ::Vips::Image.new_from_file(file)
      #Y = (66*R + 129*G + 25*B + 128)/256 + 16
      img = img * [66.0 / 256, 129.0 / 256, 25.0 / 256]
      r, g, b = img.bandsplit
      img = r + g + b + 16.5

      mask = ::Vips::Image.new_from_array([[1.0] * 7] * 7)
      img = img.colourspace("grey16")
      img = img.conv(mask)
      sample_vips(img)
    end

    def sample_vips(img)
      w, h = img.width / 32.0, img.height / 32.0
      src = img.to_a
      Matrix.build(32, 32) do |y, x|
        src[y*h][x*w][0] / CIMG_SCALE
      end
    end
  end
end
