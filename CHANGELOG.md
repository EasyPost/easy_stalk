# Changelog

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
