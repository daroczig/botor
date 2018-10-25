#' The default, fork-safe S3 client on the top of \code{botor}
#' @return \code{s3.ServiceResource}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#service-resource}
s3 <- function() {
    botor_client('s3', type = 'resource')
}


#' Split the bucket name and object key from the S3 URI
#' @inheritParams s3_object
#' @return list
#' @keywords internal
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
    s3()$Object(
        bucket_name = uri_parts$bucket_name,
        key = uri_parts$key)
}


#' List all S3 buckets
#' @param simplify return bucket names as a character vector
#' @return \code{list} of \code{boto3.resources.factory.s3.Bucket} or a character vector
#' @export
#' @importFrom reticulate iter_next
s3_list_buckets <- function(simplify = TRUE) {
    buckets <- iter_next(s3()$buckets$pages())
    if (simplify == TRUE) {
        buckets <- sapply(buckets, `[[`, 'name')
    }
    buckets
}


#' Download a file from S3
#' @inheritParams s3_object
#' @param file string, location of local file
#' @param force boolean, overwrite local file if exists
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
    s3object <- s3_object(uri)
    trypy(s3object$download_file(file))
    invisible(file)
}


#' Download and read a file from S3, then clean up
#' @inheritParams s3_download_file
#' @param fun R function to read the file, eg \code{fromJSON}, \code{fread} or \code{readRDS}
#' @param ... optional params passed to \code{fun}
#' @return R object
#' @export
#' @examples \dontrun{
#' s3_read('s3://botor/example-data/mtcars.csv', read.csv)
#' s3_read('s3://botor/example-data/mtcars.csv2', read.csv2)
#' s3_read('s3://botor/example-data/mtcars.RDS', readRDS)
#' s3_read('s3://botor/example-data/mtcars.json', jsonlite::fromJSON)
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
#' @export
#' @importFrom checkmate assert_file_exists
#' @return invisibly \code{uri}
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#S3.Client.upload_file}
#' @seealso \code{\link{s3_download_file}}
#' @examples \dontrun{
#' write.csv(mtcars, '/tmp/mtcars.csv', row.names = FALSE)
#' s3_upload_file('/tmp/mtcars.csv', 's3://botor/example-data/mtcars.csv')
#' }
s3_upload_file <- function(file, uri) {
    assert_string(file)
    assert_file_exists(file)
    assert_s3_uri(uri)
    s3object <- s3_object(uri)
    trypy(s3object$upload_file(file))
    invisible(uri)
}


#' Write an R object into S3
#' @param x R object
#' @param fun R function with \code{file} argument to write \code{x} to disk before uploading, eg \code{write.csv}, \code{write_json} or \code{saveRDS}
#' @inheritParams s3_object
#' @param ... optional further arguments passed to \code{fun}
#' @export
#' @note The temp file used for this operation is automatically removed.
#' @examples \dontrun{
#' s3_write(mtcars, write.csv, 's3://botor/example-data/mtcars.csv', row.names = FALSE)
#' s3_write(mtcars, write.csv2, 's3://botor/example-data/mtcars.csv2', row.names = FALSE)
#' s3_write(mtcars, jsonlite::write_json, 's3://botor/example-data/mtcars.json', row.names = FALSE)
#' s3_write(mtcars, saveRDS, 's3://botor/example-data/mtcars.RDS')
#' }
s3_write <- function(x, fun, uri, ...) {

    t <- tempfile()
    on.exit(unlink(t))

    if (deparse(substitute(fun)) %in% c('jsonlite::write_json', 'write_json')) {
        fun(x, path = t, ...)
    } else {
        fun(x, file = t, ...)
    }

    s3_upload_file(t, uri)

}


#' List objects at an S3 path
#' @param uri string, should start with \code{s3://}, then bucket name and object key prefix
#' @return \code{data.frame} with bucket name, key/path, size, owner, last modification timestamp
#' @author Gergely Daroczi
s3_ls <- function(uri) {

    uri_parts <- s3_split_uri(uri)

    objects <- s3()$Bucket(uri_parts$bucket_name)$objects
    objects <- objects$filter(Prefix = 'tsm/4200')
    objects <- iterate(objects$pages(), simplify = FALSE)
    objects <- unlist(objects, recursive = FALSE)

    do.call(rbind, lapply(objects, function(object) {
        object <- object$meta$`__dict__`
        data.frame(
            bucket_name = uri_parts$bucket_name,
            key = object$data$Key,
            size = object$data$Size,
            owner = object$data$Owner$DisplayName,
            last_modified = object$data$LastModified$strftime('%Y-%m-%d %H:%M:%S %Z'),
            stringsAsFactors = FALSE)
    }))

}


#' Checks if an object exists in S3
#' @inheritParams s3_object
#' @export
#' @return boolean
s3_exists <- function(uri) {
    assert_s3_uri(uri)
    s3object <- s3_object(uri)
    uri_parts <- s3_split_uri(uri)
    head <- tryCatch(
        trypy(s3()$meta$client$head_object(Bucket = uri_parts$bucket_name, Key = uri_parts$key)),
        error = function(e) e)
    invisible(!inherits(head, 'error'))
}


## TODO delete
