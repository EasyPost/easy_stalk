# EasyStalk

A simple beanstalkd client for ruby

This gem aims to provide a very simple way to use [beanstalkd](https://github.com/kr/beanstalkd) for asynchronous jobs in your ruby applications.

There are 3 main concepts presented: a Client, a Job, and a Worker.

### EasyStalk::Client

The client contains a reference to a singleton [connection pool](https://github.com/mperham/connection_pool) which connects to beanstalk instances using the [beaneater gem](https://github.com/beanstalkd/beaneater)

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
EasyStalk::Client.enqueue(job_instance, priority: pri, time_to_run: ttr, delay: wait_time, delay_until: tomorrow)
```

### EasyStalk::Job

EasyStalk::Job is a simple class based on the [interactor gem](https://github.com/collectiveidea/interactor).
The only requirements are to inherit from `EasyStalk::Job`, define the keys to serialize, and implement a call method that has access to an object name 'context', which is essentially an ostruct with your serializable keys on it.

Enqueing the Job will place it in the queue, with the appropriate settings and data. When constructing your job, just pass in a hash (or an Interactor::Context), and any keys not defined in `serializable_context_keys` will be sanitized out.

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
```
EasyStalk::Client.enqueue(TextPrintingJob.new({string_to_print: "Hello World!", scheduled_at: DateTime.now}))
```

You can further customize/override a number of settings:

```ruby
class AdvancedTextPrintingJob < EasyStalk::Job
  serializable_context_keys :string_to_print, :scheduled_at

  tube_name "custom_tube" # defaults to the class name
  tube_prefix "pref" # defaults to ENV['BEANSTALKD_TUBE_PREFIX']
  priority 20 # defaults to 500. 0 is highest priority
  time_to_run 30 # defaults to 120 seconds
  delay (60 * 5) # defaults to 0 seconds

  def call
    # Some awesome job logic
  end
end
```

To test your jobs, you can simply treat them as Interactors, and run `TextPrintingJob.call(sample_params)` to execute them directly.

### EasyStalk::Worker

The worker can be started by running work_jobs and passing in the job class to work.

```ruby
EasyStalk::Worker.new().work_jobs(YourJobClass)
```

This method currently watches a Job class's tube, running the Job as needed.
If a Job raises an exception, or otherwise is failed using Interactor's context.fail! method, it will retry up to 5 times with a modified cubic backoff with random delta.

You can also require the rake tasks in your Rakefile
```ruby
require 'easy_stalk/tasks'

```
Which will let you start a worker with the following syntax
```
$ rake easy_stalk:work_jobs[tubename]
```

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
