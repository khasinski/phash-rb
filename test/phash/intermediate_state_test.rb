# frozen_string_literal: true

require "test_helper"

class Phash::IntermediateStateTest < Minitest::Test
  FIXTURE_PATH = "test/fixtures/test.jpg"

  def setup
    @img = Vips::Image.new_from_file(FIXTURE_PATH)
  end

  # Test DCT matrix generation
  class DctMatrixTest < Minitest::Test
    def test_dct_matrix_dimensions
      dct = Phash.send(:ph_dct_matrix)
      assert_equal 32, dct.row_count
      assert_equal 32, dct.column_count
    end

    def test_dct_matrix_first_row_is_constant
      dct = Phash.send(:ph_dct_matrix)
      first_row = dct.row(0).to_a
      expected_value = (1.0 / Math.sqrt(32)).round(6)

      first_row.each do |val|
        assert_in_delta expected_value, val, 1e-6, "First row should be constant 1/sqrt(32)"
      end
    end

    def test_dct_matrix_known_values
      dct = Phash.send(:ph_dct_matrix)

      assert_in_delta 0.176777, dct[0, 0], 1e-5
      assert_in_delta 0.176777, dct[0, 1], 1e-5
      assert_in_delta 0.249699, dct[1, 0], 1e-5
      assert_in_delta 0.247294, dct[1, 1], 1e-5
      assert_in_delta(-0.012267, dct[31, 31], 1e-5)
    end

    def test_dct_matrix_uses_cosine_formula
      dct = Phash.send(:ph_dct_matrix)
      cimg_v = Math::PI / 2 / 32
      c1 = Math.sqrt(2.0 / 32)

      # Test a few specific values from rows > 0
      expected_1_5 = (c1 * Math.cos(cimg_v * 1 * (2 * 5 + 1))).round(6)
      assert_in_delta expected_1_5, dct[1, 5], 1e-6

      expected_10_20 = (c1 * Math.cos(cimg_v * 10 * (2 * 20 + 1))).round(6)
      assert_in_delta expected_10_20, dct[10, 20], 1e-6
    end

    def test_dct_matrix_is_orthogonal
      dct = Phash.send(:ph_dct_matrix)
      dct_t = dct.transpose
      product = dct * dct_t

      # An orthogonal matrix satisfies: A * A^T = I (identity matrix)
      32.times do |i|
        32.times do |j|
          expected = i == j ? 1.0 : 0.0
          assert_in_delta expected, product[i, j], 1e-4, "DCT matrix should be approximately orthogonal at [#{i},#{j}]"
        end
      end
    end
  end

  # Test image preprocessing stages
  class ImagePreprocessingTest < Minitest::Test
    FIXTURE_PATH = "test/fixtures/test.jpg"

    def setup
      @img = Vips::Image.new_from_file(FIXTURE_PATH)
    end

    def test_original_image_dimensions
      assert_equal 256, @img.width
      assert_equal 192, @img.height
    end

    def test_rgb_weighting_produces_three_bands
      weighted = @img * [66.0 / 256, 129.0 / 256, 25.0 / 256]
      assert_equal 3, weighted.bands
    end

    def test_luminance_calculation
      weighted = @img * [66.0 / 256, 129.0 / 256, 25.0 / 256]
      r, g, b = weighted.bandsplit
      luminance = r + g + b + 16.5

      # Check known pixel values
      src = luminance.to_a
      assert_in_delta 183.9296875, src[0][0][0], 0.01
      assert_in_delta 124.8125, src[100][100][0], 0.01
    end

    def test_luminance_values_are_positive
      weighted = @img * [66.0 / 256, 129.0 / 256, 25.0 / 256]
      r, g, b = weighted.bandsplit
      luminance = r + g + b + 16.5

      # Adding 16.5 ensures values stay positive even for dark pixels
      min_val = luminance.min
      # min returns an array for multi-band images, or a float for single-band
      actual_min = min_val.is_a?(Array) ? min_val[0] : min_val
      assert actual_min >= 0, "Luminance values should be non-negative"
    end
  end

  # Test convolution step
  class ConvolutionTest < Minitest::Test
    FIXTURE_PATH = "test/fixtures/test.jpg"

    def setup
      @img = Vips::Image.new_from_file(FIXTURE_PATH)
      weighted = @img * [66.0 / 256, 129.0 / 256, 25.0 / 256]
      r, g, b = weighted.bandsplit
      @luminance = r + g + b + 16.5
    end

    def test_convolution_mask_is_7x7
      mask = Vips::Image.new_from_array([[1.0] * 7] * 7)
      assert_equal 7, mask.width
      assert_equal 7, mask.height
    end

    def test_convolution_preserves_dimensions
      mask = Vips::Image.new_from_array([[1.0] * 7] * 7)
      grey = @luminance.colourspace("grey16")
      convolved = grey.conv(mask)

      assert_equal 256, convolved.width
      assert_equal 192, convolved.height
    end

    def test_convolution_produces_known_values
      mask = Vips::Image.new_from_array([[1.0] * 7] * 7)
      grey = @luminance.colourspace("grey16")
      convolved = grey.conv(mask)
      src = convolved.to_a

      assert_in_delta 2373909.0, src[0][0][0], 1.0
      assert_in_delta 1405019.0, src[100][100][0], 1.0
    end

    def test_convolution_smooths_image
      mask = Vips::Image.new_from_array([[1.0] * 7] * 7)
      grey = @luminance.colourspace("grey16")
      convolved = grey.conv(mask)

      # Convolution with uniform kernel should blur/smooth
      # Values should be much larger due to 7x7=49 multiplier effect
      src = convolved.to_a
      assert src[50][50][0] > 1000, "Convolved values should be scaled up by the kernel"
    end
  end

  # Test sampling function
  class SamplingTest < Minitest::Test
    FIXTURE_PATH = "test/fixtures/test.jpg"

    def setup
      @img = Vips::Image.new_from_file(FIXTURE_PATH)
      weighted = @img * [66.0 / 256, 129.0 / 256, 25.0 / 256]
      r, g, b = weighted.bandsplit
      luminance = r + g + b + 16.5
      mask = Vips::Image.new_from_array([[1.0] * 7] * 7)
      grey = luminance.colourspace("grey16")
      @convolved = grey.conv(mask)
    end

    def test_sampling_produces_32x32_matrix
      mat = Phash.send(:sample, @convolved)
      assert_equal 32, mat.row_count
      assert_equal 32, mat.column_count
    end

    def test_sampling_known_values
      mat = Phash.send(:sample, @convolved)

      assert_in_delta 9237.0, mat[0, 0], 1.0
      assert_in_delta 4587.0, mat[15, 15], 1.0
      assert_in_delta 5816.0, mat[31, 31], 1.0
    end

    def test_sampling_divides_by_scale_factor
      mat = Phash.send(:sample, @convolved)
      src = @convolved.to_a
      scale = Phash::CIMG_SCALE

      # Verify the sampling formula: src[y*h][x*w][0] / CIMG_SCALE
      # At position (0,0), y*h and x*w are both 0
      expected_0_0 = src[0][0][0] / scale
      assert_in_delta expected_0_0, mat[0, 0], 0.01
    end

    def test_cimg_scale_constant
      assert_equal 257, Phash::CIMG_SCALE
      assert_equal 2**8 + 1, Phash::CIMG_SCALE
    end
  end

  # Test DCT transform and binarization
  class DctTransformTest < Minitest::Test
    FIXTURE_PATH = "test/fixtures/test.jpg"

    def setup
      @img = Vips::Image.new_from_file(FIXTURE_PATH)
      weighted = @img * [66.0 / 256, 129.0 / 256, 25.0 / 256]
      r, g, b = weighted.bandsplit
      luminance = r + g + b + 16.5
      mask = Vips::Image.new_from_array([[1.0] * 7] * 7)
      grey = luminance.colourspace("grey16")
      convolved = grey.conv(mask)
      @mat = Phash.send(:sample, convolved)
      @dct = Phash.send(:ph_dct_matrix)
    end

    def test_dct_transform_produces_32x32_output
      dct_t = @dct.transpose
      out = @dct * @mat * dct_t

      assert_equal 32, out.row_count
      assert_equal 32, out.column_count
    end

    def test_dct_transform_known_values
      dct_t = @dct.transpose
      out = @dct * @mat * dct_t

      assert_in_delta 203245.16940034795, out[0, 0], 0.1
      assert_in_delta(-8895.665425301397, out[1, 1], 0.1)
      assert_in_delta 651.5966301559145, out[4, 4], 0.1
    end

    def test_low_frequency_block_extraction
      dct_t = @dct.transpose
      out = @dct * @mat * dct_t
      sub = out.minor(1..8, 1..8).to_a.flatten

      assert_equal 64, sub.size
      assert_in_delta(-8895.665425301397, sub[0], 0.1)
      assert_in_delta 190.3707961032866, sub[31], 0.1
      assert_in_delta(-948.7593845402969, sub[63], 0.1)
    end

    def test_median_calculation
      dct_t = @dct.transpose
      out = @dct * @mat * dct_t
      sub = out.minor(1..8, 1..8).to_a.flatten
      median = sub.sort[31..32].sum / 2

      assert_in_delta 173.18833390816226, median, 0.01
    end

    def test_binarization_produces_64_bits
      dct_t = @dct.transpose
      out = @dct * @mat * dct_t
      sub = out.minor(1..8, 1..8).to_a.flatten
      median = sub.sort[31..32].sum / 2
      bits = sub.reverse.map { |i| i > median ? 1 : 0 }

      assert_equal 64, bits.size
      assert bits.all? { |b| b == 0 || b == 1 }, "All bits should be 0 or 1"
    end

    def test_binarization_produces_known_bit_pattern
      dct_t = @dct.transpose
      out = @dct * @mat * dct_t
      sub = out.minor(1..8, 1..8).to_a.flatten
      median = sub.sort[31..32].sum / 2
      bits = sub.reverse.map { |i| i > median ? 1 : 0 }

      expected = "0011001110001101110011110001001011111001100101011000010101010010"
      assert_equal expected, bits.join
    end

    def test_fingerprint_from_bits
      dct_t = @dct.transpose
      out = @dct * @mat * dct_t
      sub = out.minor(1..8, 1..8).to_a.flatten
      median = sub.sort[31..32].sum / 2
      bits = sub.reverse.map { |i| i > median ? 1 : 0 }
      fingerprint = bits.join.to_i(2)

      assert_equal 3714852948054213970, fingerprint
    end
  end

  # Test Phash::Image class
  class ImageClassTest < Minitest::Test
    FIXTURE_PATH = "test/fixtures/test.jpg"

    def test_initialize_with_path
      image = Phash::Image.new(FIXTURE_PATH)
      assert_instance_of Phash::Image, image
    end

    def test_initialize_with_vips_image
      vips_img = Vips::Image.new_from_file(FIXTURE_PATH)
      image = Phash::Image.new(vips_img)
      assert_instance_of Phash::Image, image
    end

    def test_fingerprint_returns_integer
      image = Phash::Image.new(FIXTURE_PATH)
      assert_kind_of Integer, image.fingerprint
    end

    def test_fingerprint_is_cached
      image = Phash::Image.new(FIXTURE_PATH)
      fp1 = image.fingerprint
      fp2 = image.fingerprint

      assert_equal fp1.object_id, fp2.object_id, "Fingerprint should be memoized"
    end

    def test_fingerprint_matches_direct_call
      image = Phash::Image.new(FIXTURE_PATH)
      direct_fp = Phash.fingerprint(FIXTURE_PATH)

      assert_equal direct_fp, image.fingerprint
    end

    def test_distance_from_same_image_is_zero
      image1 = Phash::Image.new(FIXTURE_PATH)
      image2 = Phash::Image.new(FIXTURE_PATH)

      assert_equal 0, image1.distance_from(image2)
    end

    def test_duplicate_with_same_image
      image1 = Phash::Image.new(FIXTURE_PATH)
      image2 = Phash::Image.new(FIXTURE_PATH)

      assert image1.duplicate?(image2)
      assert image1.duplicate?(image2, threshold: 1)
    end

    def test_duplicate_uses_hamming_distance
      image1 = Phash::Image.new(FIXTURE_PATH)
      image2 = Phash::Image.new(FIXTURE_PATH)

      # XOR of identical fingerprints should be 0, giving distance 0
      distance = (image1.fingerprint ^ image2.fingerprint).to_s(2).count("1")
      assert_equal 0, distance
    end

    def test_duplicate_with_custom_threshold
      image1 = Phash::Image.new(FIXTURE_PATH)
      image2 = Phash::Image.new(FIXTURE_PATH)

      # With threshold 0, identical images should not be "duplicates" since distance < threshold (not <=)
      refute image1.duplicate?(image2, threshold: 0)

      # With threshold 1, they should be duplicates (0 < 1)
      assert image1.duplicate?(image2, threshold: 1)
    end
  end

  # Test constants
  class ConstantsTest < Minitest::Test
    def test_cimg_pi_constant
      assert_in_delta Math::PI, Phash::CIMG_PI, 1e-10
    end

    def test_cimg_v_constant
      expected = Math::PI / 2 / 32
      assert_in_delta expected, Phash::CIMG_V, 1e-10
    end

    def test_cimg_scale_constant
      assert_equal 257, Phash::CIMG_SCALE
    end
  end

  # Test Vips::Image input handling
  class VipsImageInputTest < Minitest::Test
    FIXTURE_PATH = "test/fixtures/test.jpg"

    def test_fingerprint_from_path_string
      fp = Phash.fingerprint(FIXTURE_PATH)
      assert_equal 3714852948054213970, fp
    end

    def test_fingerprint_from_vips_image
      vips_img = Vips::Image.new_from_file(FIXTURE_PATH)
      fp = Phash.fingerprint(vips_img)
      assert_equal 3714852948054213970, fp
    end

    def test_fingerprint_same_for_path_and_vips_image
      fp_path = Phash.fingerprint(FIXTURE_PATH)
      vips_img = Vips::Image.new_from_file(FIXTURE_PATH)
      fp_vips = Phash.fingerprint(vips_img)

      assert_equal fp_path, fp_vips
    end
  end
end
