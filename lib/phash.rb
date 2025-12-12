# frozen_string_literal: true

require_relative "phash/version"
require_relative "phash/image"
require "vips"
require "matrix"

module Phash
  CIMG_PI = 3.14159265358979323846
  CIMG_V = CIMG_PI / 2 / 32
  CIMG_SCALE = 2**8 + 1

  def self.distance(fingerprint1, fingerprint2)
    (fingerprint1 ^ fingerprint2).to_s(2).count('1')
  end

  def self.fingerprint(path_or_img)
    img = path_or_img.is_a?(Vips::Image) ? path_or_img : Vips::Image.new_from_file(path_or_img)
    #Y = (66*R + 129*G + 25*B + 128)/256 + 16
    img = img * [66.0 / 256, 129.0 / 256, 25.0 / 256]
    r, g, b = img.bandsplit
    img = r + g + b + 16.5

    mask = Vips::Image.new_from_array([[1.0] * 7] * 7)
    img = img.colourspace("grey16")
    img = img.conv(mask)
    mat = sample(img)
    dct = ph_dct_matrix
    dct_t = dct.transpose

    out = dct * mat * dct_t

    sub = out.minor(1..8, 1..8).to_a.flatten
    median = sub.sort[31..32].sum / 2

    sub.reverse.map {|i| i > median ? 1 : 0 }.join.to_i(2)
  end

  private

  def self.ph_dct_matrix
    @dct_matrix ||= begin
      v = 1 / Math.sqrt(32)
      c1 = Math.sqrt(2.0 / 32)

      Matrix.build(32, 32) do |y, x|
        (y < 1 ? v : c1 * Math.cos(CIMG_V * y * (2*x + 1))).round(6)
      end
    end
  end

  def self.large_image?(img)
    img.width * img.height > 250_000
  end

  def self.sample(img)
    w, h = img.width, img.height
    w_step = w / 32.0
    h_step = h / 32.0

    if large_image?(img)
      # Large images: use getpoint to avoid copying entire image to Ruby array
      Matrix.build(32, 32) do |y, x|
        img.getpoint((x * w_step).to_i, (y * h_step).to_i)[0] / CIMG_SCALE
      end
    else
      # Small images: to_a is faster than 1024 getpoint calls
      src = img.to_a
      Matrix.build(32, 32) do |y, x|
        src[(y * h_step).to_i][(x * w_step).to_i][0] / CIMG_SCALE
      end
    end
  end
end
