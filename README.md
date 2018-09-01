# botor: Reticulate wrapper on 'boto3'

This R package provides access to the 'Amazon Web Services' ('AWS') 'SDK' via the 'boto3' Python module and some convenient helper functions and workarounds, eg taking care of spawning new resources in forked R processes.

Quick example:

```r
system.time(library(botor))
#>    user  system elapsed 
#>   0.753   0.055   0.815
system.time(assert_boto3_available())
#>    user  system elapsed 
#>   0.341   0.283   0.445
system.time(boto3_version())[['elapsed']]
#> [1] 0.001
system.time(s3_list_buckets())[['elapsed']]
#> [1] 1.426
system.time(s3_list_buckets())[['elapsed']]
#> [1] 0.323
library(parallel)
simplify2array(mclapply(1:4, function(i) system.time(s3_list_buckets())[['elapsed']], mc.cores = 2))
#> [1] 1.359 1.356 0.406 0.397
library(memoise)
s3_list_buckets <- memoise(s3_list_buckets)
simplify2array(mclapply(1:4, function(i) system.time(s3_list_buckets())[['elapsed']], mc.cores = 2))
#> [1] 1.330 1.332 0.000 0.000
```
