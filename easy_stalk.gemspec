Gem::Specification.new do |s|
  s.name        = 'easy_stalk'
  s.version     = '0.1.0'
  s.date        = '2018-01-09'
  s.summary     = 'EasyStalk - An easy way to use beanstalkd for jobs'
  s.description = 'A simple beanstalk client, worker, and job setup'
  s.authors     = ['Jing-ta Chow']
  s.email       = 'dev@easypost.com'

  s.add_dependency "beaneater", '~> 1.0'
  s.add_dependency "ezpool", '~> 1.0'
  s.add_dependency "interactor", '~> 3.1'
  s.files       = [
    'lib/easy_stalk.rb',
    'lib/easy_stalk/client.rb',
    'lib/easy_stalk/configuration.rb',
    'lib/easy_stalk/descendant_tracking.rb',
    'lib/easy_stalk/job.rb',
    'lib/easy_stalk/tasks.rb',
    'lib/easy_stalk/test.rb',
    'lib/easy_stalk/test/immediate_job_runner.rb',
    'lib/easy_stalk/test/job.rb',
    'lib/easy_stalk/worker.rb'
  ]
  s.homepage    = 'https://github.com/EasyPost/easy_stalk'
  s.license     = 'MIT'

  s.add_development_dependency "bundler", "~> 1.12"
  s.add_development_dependency "rspec", "~> 3.0"
end
