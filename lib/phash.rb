# frozen_string_literal: true

require_relative "phash/version"
require_relative "phash/image"
require_relative "phash/common"
require_relative "phash/rmagick"
require_relative "phash/vips"
require "matrix"

module Phash


  def self.fingerprint(file, engine: nil)
    engine ||= self.engine

    if engine == :vips
      Phash::Vips.new.call(file) if defined?(Vips)
    elsif engine == :rmagick
      Phash::Rmagick.new.call(file) if defined?(Magick)
    else
      raise ArgumentError, "Unknown engine: #{engine}"
    end
  end

  def self.engine
    @engine ||= autodetect
  end

  def self.engine=(engine)
    @engine = engine
  end

  def self.autodetect
    if defined?(Vips)
      :vips
    elsif defined?(Magick)
      :rmagick
    else
      raise RuntimeError, "No supported engine found"
    end
  end
end
