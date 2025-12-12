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
      Phash.distance(fingerprint, other_image.fingerprint)
    end
  end
end
