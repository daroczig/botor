# botor: Reticulate wrapper on 'boto3'

This R package provides access to the 'Amazon Web Services' ('AWS') 'SDK' via the 'boto3' Python module and some convenient helper functions and workarounds, eg taking care of spawning new resources in forked R processes.

Quick example:

1. Load the `botor` package with a lazy Python `import` on `boto3` in the background:

```r
system.time(library(botor))
#>    user  system elapsed 
#>   0.753   0.055   0.815
```

2. Actual `boto3` import happens on first usage:

```r
system.time(assert_boto3_available())
#>    user  system elapsed 
#>   0.341   0.283   0.445
```

3. Listing all S3 buckets takes some time as it will first initialize the S3 client:

```r
system.time(s3_list_buckets())[['elapsed']]
#> [1] 1.426
```

4. But the second query is much faster as reusing the same `s3` Boto3 resource:

```r
system.time(s3_list_buckets())[['elapsed']]
#> [1] 0.323
```

5. Unfortunately, sharing the same Boto3 resource between (forked) processes is not ideal, so `botor` will take care of that by spawning new resources in the forked threads:

```
library(parallel)
simplify2array(mclapply(1:4, function(i) system.time(s3_list_buckets())[['elapsed']], mc.cores = 2))
#> [1] 1.359 1.356 0.406 0.397
```

6. Want to speed it up more?

```r
library(memoise)
s3_list_buckets <- memoise(s3_list_buckets)
simplify2array(mclapply(1:4, function(i) system.time(s3_list_buckets())[['elapsed']], mc.cores = 2))
#> [1] 1.330 1.332 0.000 0.000
```
