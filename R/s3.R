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
#' @inheritParams s3_object
#' @return list
#' @export
s3_split_uri <- function(uri) {
    assert_s3_uri(uri)
    path <- sub('^s3://', '', uri)
    list(
        bucket_name = sub('/.*$', '', path),
        key = sub('^[a-z0-9][a-z0-9\\.-]+[a-z0-9]/', '', path)
    )
}


#' Create an S3 Object reference from an URI
#' @param uri string, URI of an S3 object, should start with \code{s3://}, then bucket name and object key
#' @return \code{s3$Object}
#' @export
s3_object <- function(uri) {
    uri_parts <- s3_split_uri(uri)
    s3$Object(
        bucket_name = uri_parts$bucket_name,
        key = uri_parts$key)
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


#' Download a file from S3
#' @inheritParams s3_object
#' @param file string, location of local file
#' @param overwrite boolean, overwrite local file if exists
#' @export
#' @importFrom checkmate assert_string assert_directory_exists assert_flag
#' @return invisibly \code{file}
#' @examples \dontrun{
#' s3_download_file('s3://botor/example-data/mtcars.csv', tempfile())
#' }
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#S3.Client.download_file}
s3_download_file <- function(uri, file, force = TRUE) {
    assert_string(file)
    assert_directory_exists(dirname(file))
    if (force == FALSE & file.exists(file)) {
        stop(paste(file, 'already exists'))
    }
    assert_s3_uri(uri)
    assert_flag(force)
    assert_s3()
    s3object <- s3_object(uri)
    trypy(s3object$download_file(file))
    invisible(file)
}


#' Download and read a file from S3, then clean up
#' @inheritParams s3_download_file
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

    s3_download_file(uri, t)
    fun(t, ...)

}


#' Upload a file to S3
#' @inheritParams s3_object
#' @param file string, location of local file
#' @param overwrite boolean, overwrite local file if exists
#' @export
#' @importFrom checkmate assert_file_exists
#' @return invisibly \code{uri}
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#S3.Client.upload_file}
#' @seealso \code{\link{s3_download_file}}
s3_upload_file <- function(file, uri) {
    assert_string(file)
    assert_file_exists(file)
    assert_s3_uri(uri)
    assert_s3()
    s3object <- s3_object(uri)
    trypy(s3object$upload_file(file))
    invisible(uri)
}
