# Changelog

## 0.1.3 (2018-12-06)

 - Fixed bug where subclasses of EasyStalk::Job could not be used as an Abstract Base Class

## 0.1.2 (2018-01-12)

 - Fixed bug in rake task that broke compatibility with non-Rails systems

## 0.1.1 (2018-01-10)

 - Fixed bug in 'immediate job runner' testing infrastructure

## 0.1.0 (2018-01-09)

 - Fixed off-by-one error in retry_times. Retry_times values MUST BE INCREMENTED BY 1 to maintain old behavior
 - Fixed bug where connections are leaked when max_age is reached and new connections are created
 - Added white- and black-listing worker tubes

## 0.0.10 (2017-06-14)

 - Fix bug with worker rake task
 - Rake task raises on invalid tubes
 - Improve the default worker to default to all jobs when receiving an empty list

## 0.0.9 (2017-05-02)

 - Job retry counts are configurable globally and on a per-job level

## 0.0.8 (2017-02-16)

 - Change workers to cycle through available connections periodically (based on the new
   `$BEANSTALKD_WORKER_RECONNECT_SECONDS` parameter) instead of pinning to one
   beanstalkd server until the process is restarted
 - Wrap the `reserve-with-timeout` call in `Timeout` for those weird times when beanstalkd loses
   track of pending workers

## 0.0.7 (2016-09-15)

Initial release
