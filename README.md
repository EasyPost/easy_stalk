# EasyStalk

[![CI](https://github.com/EasyPost/easy_stalk/workflows/CI/badge.svg)](https://github.com/EasyPost/easy_stalk/actions?query=workflow%3ACI)

A simple beanstalkd client for ruby

This gem aims to provide a very simple way to use [beanstalkd](https://github.com/kr/beanstalkd) for asynchronous jobs in your ruby applications.

There are several important concepts:
* Job (`EasyStalk::Job`) - data produced to a specific topic
* Consumer (`EasyStalk::Consumer`) - a Ruby class that is assigned to one or more topics and acts on a job
* Client (`EasyStalk::Client`) - can add jobs to or consume jobs from some number of tubes and servers

## Concepts

### `EasyStalk::Job`

```ruby
class TextPrintingJob < EasyStalk::Consumer
  assign 'text_printing'

  def call(string_to_print:, scheduled_at:)
    puts "Job enqueued at #{scheduled_at} is running and saying #{string_to_print}"
  end
end
```

To enqueue an instance of a job:

```ruby
TextPrintingJob.enqueue({string_to_print: "Hello World!", scheduled_at: Time.now})
```

To enqueue the job manually:

```ruby
EasyStalk::Client.default.push(
    {string_to_print: "Hello World!", scheduled_at: Time.now}, tube: 'text_printing'
)
```

### `EasyStalk::Client`

### `EasyStalk::Dispatcher`

```ruby
EasyStalk::Dispatcher.call
```

This method currently watches a Job class's tube, running the Job as needed.
If a Job raises an exception, or otherwise is failed using Interactor's context.fail! method, it will retry up to 5 times with a modified cubic backoff with random delta.

If you wish to override the job failure logging, you can pass in an object that responds to call to the `work` function as a named parameter called `on_fail`.
This will be passed the job class object, the job data as a string, and the exception that was raised for logging or alerting purposes.

```ruby
failure_handler = Proc.new { |job_class, job_data, ex| EasyStalk.logger.error "#{ex.message} - #{job_data}" }
EasyStalk::Worker.new().work(YourJobClass, on_fail: failure_logger)
```


You can also require the rake tasks in your Rakefile

```ruby
require 'easy_stalk/tasks'

```

Which will let you start a worker with the following syntax

```sh
$ rake easy_stalk:work
```

or with specific job classes

```sh
$ rake easy_stalk:work[tubename1,tubename2]
```

## Configuration
A number of options are configurable in the gem via a config block.
```ruby
EasyStalk.configure do |config|
  config.logger = MyLogger.new
  config.default_worker_on_fail = Proc.new { |job_class, job_data, ex| EasyStalk.logger.error "#{ex.message} - #{job_data}" }
  config.default_priority = 10
  config.default_time_to_run = 60
  config.default_delay = 60
  config.beanstalkd_urls = ["localhost:11300", "127.0.0.1:11300"]
  config.pool_size = 10
  config.timeout_seconds = 60
end
```

## Testing
When adding tests for your code you have the ability to run your tests via the standard beanstalk tube and workers, or to run the jobs immediately.
To activate the immediate job runner you can add the following command to your test code (e.g. in the before hook):
```
require "easy_stalk/test"
EasyStalk::Extensions::ImmediateJobRunner.activate!
```
To deactivate the immediate job runner you can add the following command to your test code (e.g. in the after hook):
```
require "easy_stalk/test"
EasyStalk::Extensions::ImmediateJobRunner.deactivate!
```
Please note, after activate the ImmediateJobRunner all subsequent jobs will be run immediately.
Default behavior of the ImmediateJobRunner is to run through beanstalk and to be picked up by a worker.  Whereas when ImmediateJobRunner is activated beanstalk is bypassed and the job is run directly.

## Other notes

You can set `EasyStalk.logger` with your desired logger instance for some pitiful output.
You can view all defined job classes with `EasyStalk::Job.descendants`
Pull requests / feedback welcome!

More docs coming soon!



#### TODOS:
* break out descendant tracking into a separate gem?
* add in raketasks
* add in docs for usage (including config logging)
* improve worker configurability (custom retry backoff, retry count, etc)
