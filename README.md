# EasyStalk

A simple beanstalkd client for ruby

This gem aims to provide a very simple way to use [beanstalkd](https://github.com/kr/beanstalkd) for asynchronous jobs in your ruby applications.

There are 3 main concepts presented: a Job, a Client, and a Worker.


### Updates

To update EasyStalk, please make sure the appropriate changes are made in the following places:
* `easy_stalk.gemspec`
* `lib/easy_stalk.rb`
* `CHANGELOG.md`

In addition, please rebundle the gems so that the version in `Gemfile.lock` gets updated.


### EasyStalk::Job

EasyStalk::Job is a simple class based on the [interactor gem](https://github.com/collectiveidea/interactor).
The only requirements are to inherit from `EasyStalk::Job`, define the keys to serialize using the `serialize_context_keys` method, and implement a call method that has access to an object name 'context', which is essentially an ostruct with your serializable keys on it.

When constructing your job, just pass in a hash (or an Interactor::Context), and any keys not defined in `serializable_context_keys` will be sanitized out upon enqueue.
Enqueing the Job will place it in the appropriate beanstalkd queue, with the defined job settings and context data specified by the `serializable_context_keys`.

```ruby
class TextPrintingJob < EasyStalk::Job
  serializable_context_keys :string_to_print, :scheduled_at

  def call
    text = context.string_to_print
    enqueued_time = context.scheduled_at

    puts "Job enqueued at #{enqueued_time} is running and saying #{text}"
  end
end

# To enqueue the job
job_instance = TextPrintingJob.new({string_to_print: "Hello World!", scheduled_at: DateTime.now})
EasyStalk::Client.enqueue(job_instance)
```

You can further customize/override a number of settings:

```ruby
class AdvancedTextPrintingJob < EasyStalk::Job
  serializable_context_keys :string_to_print, :scheduled_at

  tube_name "custom_tube" # defaults to the class name
  tube_prefix "custom.tube.prefix." # defaults to ENV['BEANSTALKD_TUBE_PREFIX']
  priority 20 # defaults to 500. 0 is highest priority
  time_to_run 30 # defaults to 120 seconds
  delay (60 * 5) # defaults to 0 seconds

  def call
    # Some awesome job logic
  end
end
```

To test your jobs, you can simply treat them as Interactors, and run `TextPrintingJob.call(sample_params)` to execute them directly.

 Note, when processing the job via the Worker, the keys available in the context will only be the values specified by `serializable_context_keys`, but If you call the job directly, for example in tests, the context will have access to anything passed in.


### EasyStalk::Client

The client contains a reference to a singleton [connection pool](https://github.com/EasyPost/EzPool) which connects to beanstalk instances using the [beaneater gem](https://github.com/beanstalkd/beaneater)

The client requires an ENV var of `BEANSTALKD_URLS` to be present, which contains a comma separated string of host:port combinations which are randomly selected for connections.

Other configurable values are `BEANSTALKD_TIMEOUT_SECONDS` which defaults to 10, and `BEANSTALKD_POOL_SIZE` which defaults to 30, and are passed along to the connection pool.

Using the client is as simple as calling `EasyStalk::Client.enqueue(job_instance)`.
By default, the job's default time_to_run, priority, and delay will be used, and the job will be scheduled to run immediately.

You can override this behavior explicitly by passing in custom values:
```ruby
pri = 1 # Lower is higher priority
ttr = 10 # seconds to run the job for
wait_time = 5 # seconds to wait until job is ready. NOTE: gets overridden if delay_until is present
tomorrow = DateTime.now + 1 # target datetime used to calculate delay
job_instance = TextPrintingJob.new({string_to_print: "Hello World!", scheduled_at: DateTime.now})
EasyStalk::Client.enqueue(job_instance, priority: pri, time_to_run: ttr, delay: wait_time, delay_until: tomorrow)
```

### EasyStalk::Worker

The worker can be started by running `work`.

```ruby
EasyStalk::Worker.new().work
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
  config.default_tube_prefix = "tube.prefix.name."
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
