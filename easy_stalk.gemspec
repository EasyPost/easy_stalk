# frozen_string_literal: true

require File.expand_path('lib/easy_stalk/version', __dir__)

Gem::Specification.new do |spec|
  spec.name        = 'easy_stalk'
  spec.version     = EasyStalk::VERSION
  spec.date        = '2018-12-06'
  spec.summary     = 'EasyStalk - An easy way to use beanstalkd for jobs'
  spec.description = 'A simple beanstalk client, worker, and job setup'
  spec.authors     = ['Jing-ta Chow']
  spec.email       = 'dev@easypost.com'
  spec.license     = 'MIT'

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  if spec.respond_to?(:metadata)
    spec.metadata['homepage_uri'] = 'https://github.com/EasyPost/easy_stalk'
    spec.metadata['source_code_uri'] = 'https://github.com/EasyPost/easy_stalk'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.add_dependency 'beaneater', '~> 1.0'
  spec.add_dependency 'ezpool', '~> 1.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop-airbnb', '~> 3.0'
end
