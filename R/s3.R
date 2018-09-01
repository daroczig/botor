s3 <- NULL


#' Make sure S3 is available as a resource
#' @return boto3 resource
#' @keywords internal
assert_s3 <- function() {
    assert_boto3_available()
    if (is.null(s3) || attr(s3, 'pid') != Sys.getpid()) {
        utils::assignInMyNamespace('s3', structure(botor$resource('s3'), pid = Sys.getpid()))
    }
}


#' List all S3 buckets
#' @param simplify return bucket names as a character vector
#' @return \code{list} of \code{boto3.resources.factory.s3.Bucket} or a character vector
#' @export
#' @importFrom reticulate iter_next
s3_list_buckets <- function(simplify = TRUE) {
    assert_s3()
    buckets <- iter_next(s3$buckets$pages())
    if (simplify == TRUE) {
        buckets <- sapply(buckets, `[[`, 'name')
    }
    buckets
}
