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
#' @return \code{list} of \code{Bucket}s
#' @export
#' @importFrom reticulate iter_next
s3_list_buckets <- function() {
    assert_s3()
    iter_next(s3$buckets$pages())
}
