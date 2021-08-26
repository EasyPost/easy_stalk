# EasyStalk

[![CI](https://github.com/EasyPost/easy_stalk/workflows/CI/badge.svg)](https://github.com/EasyPost/easy_stalk/actions?query=workflow%3ACI)

A simple beanstalkd client for ruby

This gem aims to provide a very simple way to use [beanstalkd](https://github.com/kr/beanstalkd) for asynchronous jobs in your ruby applications.

## Configuration

A number of options are configurable in the gem via a config block.
```ruby
EasyStalk.logger = MyLogger.new
EasyStalk.default_worker_on_fail = Proc.new { |job_class, job_data, ex| EasyStalk.logger.error "#{ex.message} - #{job_data}" }
EasyStalk.default_priority = 10
EasyStalk.default_time_to_run = 60
EasyStalk.default_delay = 60
EasyStalk.beanstalkd_urls = ["localhost:11300", "127.0.0.1:11300"]
EasyStalk.pool_size = 10
EasyStalk.timeout_seconds = 60
```

## Concepts

There are several important concepts:
* Job (`EasyStalk::Job`) - data produced to a specific topic
* Consumer (`EasyStalk::Consumer`) - a Ruby class that is assigned to one or more topics and acts on a job
* Client (`EasyStalk::Client`) - can add jobs to or consume jobs from some number of tubes and servers

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

```ruby
class TextPrintingJob < EasyStalk::Consumer
  assign 'text_printing'

  def call(string_to_print:, scheduled_at:)
    job.releases # how many times have tried to process this?
  end
end
```

### `EasyStalk::Client`

### `EasyStalk::Dispatcher`

```ruby
EasyStalk::Dispatcher.call
```

## Testing
