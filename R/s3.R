s3 <- NULL


#' Init S3 resource
#' @return boto3 resource
#' @keywords internal
s3_init <- function() {
    if (is.null(s3)) {
        utils::assignInMyNamespace('s3', botor$resource('s3'))
    }
}


#' Lists all S3 buckets
#' @return list
#' @export
#' @importFrom reticulate iter_next
s3_list_buckets <- function() {
    s3_init()
    iter_next(s3$buckets$pages())
}
