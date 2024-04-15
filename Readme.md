# expbackoff

bash script that defines a expbackoff function.  
the function can be used to keep retrying commands that intermittently or often fail.  
it is especially useful for things where you might be locked out or throttled if trying too fast or if you expect success eventually.  


it runs the command passed to it and takes care of backing off as configured, exiting right away.  

status is held in a temp directory named after the hash of the command, upon successful  
run of the command this temp directory is deleted.  

Example:
suppose the command we want to run is 'command_that_mostly_fails'

we call the function, passing the command: `expbackoff command_that_mostly_fails`  
the command fails with an exit code other than 0, _expbackoff_ creates the temp directory `/tmp/5606152175bb1861bdb26a139b168cf5` and stores the current timestamp and a retry counter.  

everytime the function is called, what I called _distance_ is calculated, this is the number of seconds that should have been passed since last trying to run the command, so the current amount of backoff.  

this calculation looks like this: `$(( (EXPBACKOFF_BASE * EXPBACKOFF_FACTOR) ** LAST_TRY ))`  

if the function is called whithin the _distance_ it exits with code 2 and does not update the timestamp or increase the counter.  
