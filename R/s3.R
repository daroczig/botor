#' Raw access to boto3.resource('s3')
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#service-resource}
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


#' Split the bucket name and object key from the S3 URI
#' @inheritParams check_s3_uri
#' @return list
#' @export
s3_split_path <- function(uri) {
    assert_s3_uri(uri)
    path <- sub('^s3://', '', uri)
    list(
        bucket_name = sub('/.*$', '', path),
        key = sub('^[a-z0-9][a-z0-9\\.-]+[a-z0-9]/', '', path)
    )
}

## TODO s3_object_to_path

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


#' Download a file from S3
#' @inheritParams check_s3_uri
#' @param file string, location of local file
#' @param overwrite boolean, overwrite local file if exists
#' @export
#' @importFrom checkmate assert_string assert_directory_exists assert_flag
#' @return invisibly \code{file}
#' @examples \dontrun{
#' s3_download('s3://botor/example-data/mtcars.csv', tempfile())
#' }
s3_download <- function(uri, file, force = TRUE) {
    assert_string(file)
    assert_directory_exists(dirname(file))
    if (force == FALSE & file.exists(file)) {
        stop(paste(file, 'already exists'))
    }
    assert_s3_uri(uri)
    assert_flag(force)
    assert_s3()
    s3object <- s3$Object(bucket_name = s3_split_path(object)$bucket_name, key = s3_split_path(object)$key)
    trypy(s3object$download_file(file))
    invisible(file)
}


#' Download and read a file from S3, then clean up
#' @inheritParams s3_download
#' @param fun R function to read the file, eg \code{fromJSON}, \code{fread} or \code{readRDS}
#' @return R object
#' @export
#' @examples \dontrun{
#' s3_read('s3://botor/example-data/mtcars.csv', read.csv)
#' s3_read('s3://botor/example-data/mtcars.csv2', read.csv, sep = ';')
#' }
s3_read <- function(uri, fun, ...) {

    t <- tempfile()
    on.exit(unlink(t))

    s3_download(uri, t)
    fun(t, ...)

}
