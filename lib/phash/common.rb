module Phash
  class Common
    CIMG_PI = 3.14159265358979323846
    CIMG_V = CIMG_PI / 2 / 32
    CIMG_SCALE = 2**8 + 1

    def call(file)
      mat = load_and_transform(file)

      dct = ph_dct_matrix
      dct_t = dct.transpose

      out = dct * mat * dct_t

      sub = out.minor(1..8, 1..8).to_a.flatten
      median = sub.sort[31..32].sum / 2

      sub.reverse.map {|i| i > median ? 1 : 0 }.join.to_i(2)
    end

    def load_and_transform(file)
      raise NotImplementedError
    end

    def ph_dct_matrix
      v = 1 / Math.sqrt(32)
      c1 = Math.sqrt(2.0 / 32)

      Matrix.build(32, 32) do |y, x|
        (y < 1 ? v : c1 * Math.cos(CIMG_V * y * (2*x + 1))).round(6)
      end
    end
  end
end
