# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
eval File.read(
  File.expand_path('../lib/bcbiff.rb', __FILE__)
).lines.find { |line|
  /BCBIFF_VERSION/ =~ line
} if !defined?(BCBIFF_VERSION)

Gem::Specification.new do |gem|
  gem.name          = "bcbiff"
  gem.version       = BCBIFF_VERSION
  gem.authors       = ["Akinori MUSHA"]
  gem.email         = ["knu@idaemons.org"]
  gem.homepage      = "https://github.com/knu/bcbiff"
  gem.licenses      = ["2-clause BSDL"]
  gem.description   = <<'EOS'
Bcbiff checks the Inbox folder on an IMAP server for unread mails and
sends a notification for each.  Ideal for enabling push notification
for your Gmail account using Boxcar.
EOS
  gem.summary       = %q{bcbiff(1) - Boxcar based IMAP biff}

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.extra_rdoc_files = [
    "LICENSE.txt",
    "README.md"
  ]

  gem.add_runtime_dependency("mail", [">= 0"])
  gem.add_development_dependency("rdoc", ["> 2.4.2"])
  gem.add_development_dependency("bundler", [">= 1.2"])
end
