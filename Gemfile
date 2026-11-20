source 'https://rubygems.org'

gemspec

# grpc ships Windows (x64-mingw-ucrt) precompiled gems only through 1.84.1;
# 1.85.0+ is source-only on Windows and needs a full C/C++ build toolchain.
# Pin it on Windows so `bundle install` uses the prebuilt binary. On Linux/macOS
# (CI) every grpc version has binaries, so the pin is Windows-only.
gem 'grpc', '~> 1.84.1' if Gem.win_platform?

group :test do
  gem 'minitest', '~> 5.20'
end
