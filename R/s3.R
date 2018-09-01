s3 <- NULL


#' Init S3 resource
#' @return boto3 resource
#' @keywords internal
s3_init <- function() {
    if (is.null(s3) || attr(s3, 'pid') != Sys.getpid()) {
        utils::assignInMyNamespace('s3', structure(botor$resource('s3'), pid = Sys.getpid()))
    }
}


#' Lists all S3 buckets
#' @return \code{list} of \code{Bucket}s
#' @export
#' @importFrom reticulate iter_next
s3_list_buckets <- function() {
    s3_init()
    iter_next(s3$buckets$pages())
}
