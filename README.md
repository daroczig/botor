# botor: Reticulate wrapper on 'boto3'

This R package provides access to the 'Amazon Web Services' ('AWS') 'SDK' via the 'boto3' Python module and some convenient helper functions and workarounds, eg taking care of spawning new resources in forked R processes.

## Installation

`botor` is not on CRAN yet, please install from GitHub:

```r
devtools::install_github('darociz/botor')
```

## Loading the package

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

`botor` will use the credentials and related options set in the [environmental variables](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/configuration.html#configuration) or in the `~/.aws/config` and `~/.aws/credentials` files. If you need to specify a custom profile or AWS region, please set the related environment variable before loading `botor`, as there are no intentions to provide helper functions passing parameters to `boto3.session.Session`.

## Using the raw Boto3 module

The `botor` package provides the `botor` object with full access to the Boto3 Python SDK. Quick example on listing all S3 buckets:

```r
library(botor)
s3 <- botor$resource('s3')
iter_next(s3$buckets$pages())
```

Note that this approach requires a stable understanding of the Boto3 Python module, plus a decent familiarity with `reticulate` as well -- so you might want to rather consider using the helper functions described below.

## Convenient helper functions

`botor` comes with a bunch of R helper functions for the most common AWS actions, like interacting with S3 or KMS. Note, that the list of these functions is pretty limited for now, but you can always fall back to the raw Boto3 functions if needed. PRs on new helper functions are appreciated :)

Examples:

1. Listing all S3 buckets takes some time as it will first initialize the S3 Boto3 client in the background:

    ```r
    system.time(s3_list_buckets())[['elapsed']]
    #> [1] 1.426
    ```

2. But the second query is much faster as reusing the same `s3` Boto3 resource:

    ```r
    system.time(s3_list_buckets())[['elapsed']]
    #> [1] 0.323
    ```

3. Unfortunately, sharing the same Boto3 resource between (forked) processes is not ideal, so `botor` will take care of that by spawning new resources in the forked threads:

    ```r
    library(parallel)
    simplify2array(mclapply(1:4, function(i) system.time(s3_list_buckets())[['elapsed']], mc.cores = 2))
    #> [1] 1.359 1.356 0.406 0.397
    ```

4. Want to speed it up more?

    ```r
    library(memoise)
    s3_list_buckets <- memoise(s3_list_buckets)
    simplify2array(mclapply(1:4, function(i) system.time(s3_list_buckets())[['elapsed']], mc.cores = 2))
    #> [1] 1.330 1.332 0.000 0.000
    ```

The currently supported resources and features via helper functions:

* S3: ...
* KMS: ...


## Error handling

The convenient helper functions try to suppress the boring Python traceback and provide you only the most relevant information on the error. If you want to see the full tracelog and more details after an error, call `reticulate::py_last_error()`. When working with the raw `boto3` wrapper, you may find `botor:::trypy` useful as well.

```r
s3_download('s3://BOTOR/example-data/mtcars.csv', tempfile())
#> Error in s3_download('s3://BOTOR/example-data/mtcars.csv', tempfile()) : 
#>   Python `ClientError`: An error occurred (403) when calling the HeadObject operation: Forbidden

s3_read('s3://botor/example-data/mtcars2.csv', read.csv)
#> Error in s3_download(object, t) : 
#>   Python `ClientError`: An error occurred (404) when calling the HeadObject operation: Not Found
```
