# frozen_string_literal: true

require "test_helper"

class Phash::Test < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Phash::VERSION
  end

  def test_calculates_fingerprint_for_image
    assert_equal 3714852948054213970, Phash.fingerprint("test/fixtures/test.jpg")
  end

  def test_calculates_fingerprint_for_image_with_rmagick
    assert_equal Phash.fingerprint("test/fixtures/test.jpg", engine: :vips), Phash.fingerprint("test/fixtures/test.jpg", engine: :rmagick)
  end
end
