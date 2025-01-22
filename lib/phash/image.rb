module Phash
  class Image
    def initialize(image)
      @image = image
    end

    def fingerprint
      @fingerprint ||= Phash.fingerprint(@image)
    end

    def duplicate?(other_image, threshold: 10)
      distance_from(other_image) < threshold
    end

    def distance_from(other_image)
      (fingerprint ^ other_image.fingerprint).to_s(2).count('1')
    end
  end
end
