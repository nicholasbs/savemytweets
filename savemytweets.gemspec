# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "savemytweets/version"

Gem::Specification.new do |s|
  s.name        = "savemytweets"
  s.version     = SaveMyTweets::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Nicholas Bergson-Shilcock"]
  s.email       = ["me@nicholasbs.net"]
  s.homepage    = "http://github.com/nicholasbs/savemytweets"
  s.summary     = %q{Command line tool to archive your tweets.}
  s.description = %q{SaveMyTweets downloads the most recent 3,200 tweets from a given user and stores them in MongoDB. You can run it multiple times and it will only download the tweets since the last time it was run for that user.}

  s.rubyforge_project = "savemytweets"

  s.add_dependency "trollop", "~> 1.16.2"
  s.add_dependency "twitter"
  s.add_dependency "mongo"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

end
