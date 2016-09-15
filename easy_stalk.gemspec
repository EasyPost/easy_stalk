Gem::Specification.new do |s|
  s.name        = 'easy_stalk'
  s.version     = '0.0.1'
  s.date        = '2016-09-15'
  s.summary     = 'EasyStalk - An easy way to use beanstalkd for jobs'
  s.description = 'A simple beanstalk client, worker, and job setup'
  s.authors     = ['Jing-ta Chow']
  s.email       = 'dev@easypost.com'

  s.add_dependency "beaneater"
  s.add_dependency "connection_pool"
  s.add_dependency "interactor"
  s.files       = [
    'lib/easy_stalk.rb',
    'lib/easy_stalk/job.rb',
    'lib/easy_stalk/client.rb',
    'lib/easy_stalk/worker.rb',
  ]
  s.homepage    = 'https://github.com/EasyPost/easy_stalk'
  s.license     = 'MIT'


  s.add_development_dependency "bundler", "~> 1.12"
  s.add_development_dependency "rspec", "~> 3.0"
end
