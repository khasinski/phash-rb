# Phash

[![Gem Version](https://badge.fury.io/rb/phash-rb.svg)](https://badge.fury.io/rb/phash-rb)
[![Test](https://github.com/khasinski/phash-rb/workflows/Phash-rb/badge.svg)](https://github.com/khasinski/phash-rb/actions/workflows/main.yml)

Phashion replacement without native extension (however it currently relies on libvips). Compatible with pHash 0.9.6.

## Requirements

- libvips (see requirements for [ruby-vips](https://github.com/libvips/ruby-vips))
- Ruby 2.6.0 or later

## Installation

```bash
bundle add phash-rb
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install phash-rb
```

## Usage

If you're using Phashion replace Phashion::Image with Phash::Image.

Public interface is the same as Phashion::Image.

```ruby
require 'phash'

img1 = Phash::Image.new(filename1)
img2 = Phash::Image.new(filename2)
img1.duplicate?(img2) # true
```

Optionally, you can set the minimum Hamming distance in the second argument, an options Hash:

```ruby
img1.duplicate?(img2, threshold: 5) # true

img1.duplicate?(img2, threshold: 0) # false
```

We also support the fingerprint method for storing Phash fingerprints in the database.

```ruby
require 'phash'

Phash::Image.new(filename1).fingerprint # 3714852948054213970
```

Fingerprint is also available in a command `phash`:

```bash
$ phash test/fixtures/test.jpg
3714852948054213970
```

Additionally you can pass `Vips::Image` directly to fingerprint function:
```ruby
image.class # Vips::Image
Phash::Image.new(image).fingerprint # 3714852948054213970
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/khasinski/phash-rb. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/phash-rb/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Phash project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/phash-rb/blob/main/CODE_OF_CONDUCT.md).
