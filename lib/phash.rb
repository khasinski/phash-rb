# frozen_string_literal: true

require_relative "phash/version"
require_relative "phash/image"
require "vips"
require "matrix"

module Phash
  CIMG_PI = 3.14159265358979323846
  CIMG_V = CIMG_PI / 2 / 32
  CIMG_SCALE = 2**8 + 1

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
    v = 1 / Math.sqrt(32)
    c1 = Math.sqrt(2.0 / 32)

    Matrix.build(32, 32) do |y, x|
      (y < 1 ? v : c1 * Math.cos(CIMG_V * y * (2*x + 1))).round(6)
    end
  end

  def self.sample(img)
    w, h = img.width / 32.0, img.height / 32.0
    src = img.to_a
    Matrix.build(32, 32) do |y, x|
      src[y*h][x*w][0] / CIMG_SCALE
    end
  end
end
