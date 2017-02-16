## 0.0.8

 - Change workers to cycle through available connections periodically (based on the new
   `$BEANSTALKD_WORKER_RECONNECT_SECONDS` parameter) instead of pinning to one
   beanstalkd server until the process is restarted
 - Wrap the `reserve-with-timeout` call in `Timeout` for those weird times when beanstalkd loses
   track of pending workers

## 0.0.7 (2016-09-15)

Initial release
