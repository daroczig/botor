#' The default, fork-safe Amazon Simple Storage Service (S3) client on the top of \code{botor}
#' @return \code{s3.ServiceResource}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#service-resource}
#' @importFrom logger log_trace log_debug log_info log_warn log_error
s3 <- function() {
    botor_client('s3', type = 'resource')
}


#' Split the bucket name and object key from the S3 URI
#' @inheritParams s3_object
#' @return list
#' @keywords internal
s3_split_uri <- function(uri) {
    assert_s3_uri(uri)
    ## kill URI schema
    path <- sub('^s3://', '', uri)
    ## bucket name is anything before the first slash
    bucket <- sub('/.*$', '', path)
    ## object key is the remaining bit
    key <- sub(paste0('^', bucket, '/?'), '', path)
    list(bucket_name = bucket, key = key)
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
    log_trace('Listing all S3 buckets ...')
    buckets <- iter_next(s3()$buckets$pages())
    log_debug('Found %s S3 buckets', length(buckets))
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
    log_trace('Downloading %s to %s ...', uri, shQuote(file))
    if (force == FALSE & file.exists(file)) {
        stop(paste(file, 'already exists'))
    }
    assert_s3_uri(uri)
    assert_flag(force)
    s3object <- s3_object(uri)
    trypy(s3object$download_file(file))
    log_debug('Downloaded %s bytes from %s and saved at %s', file.info(file)$size, uri, shQuote(file))
    invisible(file)
}


#' Download and read a file from S3, then clean up
#' @inheritParams s3_download_file
#' @param fun R function to read the file, eg \code{fromJSON}, \code{stream_in}, \code{fread} or \code{readRDS}
#' @param ... optional params passed to \code{fun}
#' @param extract optionally extract/decompress the file after downloading from S3 but before passing to \code{fun}
#' @return R object
#' @export
#' @examples \dontrun{
#' s3_read('s3://botor/example-data/mtcars.csv', read.csv)
#' s3_read('s3://botor/example-data/mtcars.csv', data.table::fread)
#' s3_read('s3://botor/example-data/mtcars.csv2', read.csv2)
#' s3_read('s3://botor/example-data/mtcars.RDS', readRDS)
#' s3_read('s3://botor/example-data/mtcars.json', jsonlite::fromJSON)
#' s3_read('s3://botor/example-data/mtcars.jsonl', jsonlite::stream_in)
#'
#' ## read compressed data
#' s3_read('s3://botor/example-data/mtcars.csv.gz', read.csv, extract = 'gzip')
#' s3_read('s3://botor/example-data/mtcars.csv.gz', data.table::fread, extract = 'gzip')
#' s3_read('s3://botor/example-data/mtcars.csv.bz2', read.csv, extract = 'bzip2')
#' s3_read('s3://botor/example-data/mtcars.csv.xz', read.csv, extract = 'xz')
#' }
s3_read <- function(uri, fun, ..., extract = c('none', 'gzip', 'bzip2', 'xz')) {

    t <- tempfile()
    on.exit({
        log_trace('Deleted %s', t)
        unlink(t)
    })

    s3_download_file(uri, t)

    ## decompress/extract downloaded file
    extract <- match.arg(extract)
    if (extract != 'none') {

        filesize <- file.info(t)$size

        ## gzfile can handle bzip2 and xz as well
        filecon <- gzfile(t, open = 'rb')

        ## paginate read compressed file by 1MB chunks
        ## as we have no idea about the size of the uncompressed data
        chunksize <- 1024L * 1024L
        chunks <- list(readBin(filecon, 'raw', n = chunksize))
        while (length(chunks[[length(chunks)]]) == chunksize) {
            chunks[[length(chunks) + 1]] <- readBin(filecon, 'raw', n = chunksize)
        }
        filecontent <- unlist(chunks, use.names = FALSE)
        close(filecon)

        ## overwrite compressed temp file with uncompressed data
        writeBin(filecontent, t)
        log_trace('Decompressed %s via %s from %s to %s bytes', t, extract, filesize, file.info(t)$size)

    }

    if (deparse(substitute(fun)) %in% c('jsonlite::stream_in', 'stream_in')) {
        t <- file(t)
    }

    fun(t, ...)

}


#' Upload a file to S3
#' @inheritParams s3_object
#' @param file string, location of local file
#' @param content_type content type of a file that is auto-guess if omitted
#' @export
#' @importFrom checkmate assert_file_exists
#' @importFrom reticulate import
#' @return invisibly \code{uri}
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#S3.Client.upload_file}
#' @seealso \code{\link{s3_download_file}}
#' @examples \dontrun{
#' t <- tempfile()
#' write.csv(mtcars, t, row.names = FALSE)
#' s3_upload_file(t, 's3://botor/example-data/mtcars.csv')
#' unlink(t)
#' ## note that s3_write would have been a much nicer solution for the above
#' }
s3_upload_file <- function(file, uri, content_type = mime_guess(file)) {

    assert_string(file)
    assert_file_exists(file)
    assert_s3_uri(uri)
    assert_string(content_type, na.ok = TRUE)

    ## set content type
    if (!is.na(content_type)) {
        extra_args <- list(ContentType = content_type)
    } else {
        extra_args <- NULL
    }

    log_trace('Uploading %s to %s ...', shQuote(file), uri)
    s3object <- s3_object(uri)
    trypy(s3object$upload_file(file, ExtraArgs = extra_args))
    log_debug(
        'Uploaded %s bytes from %s to %s with %s content type',
        file.info(file)$size, shQuote(file), uri, shQuote(content_type))
    invisible(uri)

}


#' Write an R object into S3
#' @param x R object
#' @param fun R function with \code{file} argument to serialize \code{x} to disk before uploading, eg \code{write.csv}, \code{write_json}, \code{stream_out} or \code{saveRDS}
#' @param compress optionally compress the file before uploading to S3. If compression is used, it's better to include the related file extension in \code{uri} as well (that is not done automatically).
#' @param ... optional further arguments passed to \code{fun}
#' @inheritParams s3_object
#' @export
#' @note The temp file used for this operation is automatically removed.
#' @examples \dontrun{
#' s3_write(mtcars, write.csv, 's3://botor/example-data/mtcars.csv', row.names = FALSE)
#' s3_write(mtcars, write.csv2, 's3://botor/example-data/mtcars.csv2', row.names = FALSE)
#' s3_write(mtcars, jsonlite::write_json, 's3://botor/example-data/mtcars.json', row.names = FALSE)
#' s3_write(mtcars, jsonlite::stream_out, 's3://botor/example-data/mtcars.jsonl', row.names = FALSE)
#' s3_write(mtcars, saveRDS, 's3://botor/example-data/mtcars.RDS')
#'
#' ## compress file after writing to disk but before uploading to S3
#' s3_write(mtcars, write.csv, 's3://botor/example-data/mtcars.csv.gz',
#'   compress = 'gzip', row.names = FALSE)
#' s3_write(mtcars, write.csv, 's3://botor/example-data/mtcars.csv.bz2',
#'   compress = 'bzip2', row.names = FALSE)
#' s3_write(mtcars, write.csv, 's3://botor/example-data/mtcars.csv.xz',
#'   compress = 'xz', row.names = FALSE)
#' }
s3_write <- function(x, fun, uri, compress = c('none', 'gzip', 'bzip2', 'xz'), ...) {

    t <- tempfile()
    on.exit({
        log_trace('Deleted %s', t)
        unlink(t)
    })

    if (deparse(substitute(fun)) %in% c('jsonlite::write_json', 'write_json')) {
        fun(x, path = t, ...)
    } else {
        if (deparse(substitute(fun)) %in% c('jsonlite::stream_out', 'stream_out')) {
            fun(x, con = file(t), ...)
        } else {
            fun(x, file = t, ...)
        }
    }
    log_trace('Wrote %s bytes to %s', file.info(t)$size, t)

    compress <- match.arg(compress)
    if (compress != 'none') {
        filesize    <- file.info(t)$size
        filecontent <- readBin(t, 'raw', n = filesize)
        compressor  <- switch(
            compress,
            'gzip'  = gzfile,
            'bzip2' = bzfile,
            'xz'    = xzfile)
        filecon <- compressor(t, open = 'wb')
        ## overwrite
        writeBin(filecontent, filecon)
        close(filecon)
        log_trace('Compressed %s via %s from %s to %s bytes', t, compress, filesize, file.info(t)$size)
    }

    s3_upload_file(t, uri)

}


#' List objects at an S3 path
#' @param uri string, should start with \code{s3://}, then bucket name and optional object key prefix
#' @return \code{data.frame} with \code{bucket_name}, object \code{key}, \code{uri} (that can be directly passed to eg \code{\link{s3_read}}), \code{size} in bytes, \code{owner} and \code{last_modified} timestamp
#' @export
#' @importFrom reticulate iterate
s3_ls <- function(uri) {

    log_trace('Recursive listing of files in %s', uri)
    uri_parts <- s3_split_uri(uri)

    objects <- s3()$Bucket(uri_parts$bucket_name)$objects
    objects <- objects$filter(Prefix = uri_parts$key)
    objects <- trypy(iterate(objects$pages(), simplify = FALSE))
    objects <- unlist(objects, recursive = FALSE)

    objects <- do.call(rbind, lapply(objects, function(object) {
        object <- object$meta$`__dict__`
        data.frame(
            bucket_name = uri_parts$bucket_name,
            key = object$data$Key,
            uri = file.path('s3:/', uri_parts$bucket_name, object$data$Key),
            size = object$data$Size,
            owner = object$data$Owner$DisplayName,
            last_modified = object$data$LastModified$strftime('%Y-%m-%d %H:%M:%S %Z'),
            stringsAsFactors = FALSE)
    }))

    log_debug('Found %s item(s) in %s', nrow(objects), uri)
    objects

}


#' Checks if an object exists in S3
#' @inheritParams s3_object
#' @export
#' @return boolean
#' @examples \dontrun{
#' s3_exists('s3://botor/example-data/mtcars.csv')
#' s3_exists('s3://botor/example-data/UNDEFINED.CSVLX')
#' }
s3_exists <- function(uri) {
    assert_s3_uri(uri)
    s3object <- s3_object(uri)
    uri_parts <- s3_split_uri(uri)
    log_trace('Checking if object at %s exist ...', uri)
    head <- tryCatch(
        trypy(s3()$meta$client$head_object(Bucket = uri_parts$bucket_name, Key = uri_parts$key)),
        error = function(e) e)
    found <- !inherits(head, 'error')
    log_debug('%s %s', uri, ifelse(found, 'found', 'not found'))
    invisible(found)
}


#' Copy an object from one S3 location to another
#' @param uri_source string, location of the source file
#' @param uri_target string, location of the target file
#' @export
#' @return invisibly \code{uri_target}
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#S3.Object.copy}
s3_copy <- function(uri_source, uri_target) {
    assert_s3_uri(uri_source)
    assert_s3_uri(uri_target)
    log_trace('Copying %s to %s ...', uri_source, uri_target)
    source <- s3_split_uri(uri_source)
    target <- s3_object(uri_target)
    trypy(target$copy(list(Bucket = source$bucket_name, Key = source$key)))
    log_debug('Copied %s to %s', uri_source, uri_target)
    invisible(uri_target)
}


#' Delete an object stored in S3
#' @inheritParams s3_object
#' @export
s3_delete <- function(uri) {
    assert_s3_uri(uri)
    log_trace('Deleting %s ...', uri)
    s3_object(uri)$delete()
    log_debug('Deleted %s', uri)
}


#' Sets tags on s3 object overwriting all existing tags. Note: tags and metadata tags are not the same
#' @param uri string, URI of an S3 object, should start with \code{s3://}, then bucket name and object key
#' @param tags named character vector, e.g. \code{c(my_first_name = 'my_first_value', my_second_name = 'my_second_value')} where names are the tag names and values are the tag values.
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#S3.Client.put_object_tagging}
s3_put_object_tagging <- function(uri, tags) {
    assert_s3_uri(uri)
    tag_set <- mapply(list, Key = names(tags), Value = tags, SIMPLIFY = FALSE, USE.NAMES = FALSE)
    ## Desired format for tag_set is
    ## list(list('Key' = 'my_first_key', 'Value' = 'my_first_value'), list('Key' = 'my_second_key', 'Value' = 'my_second_value'))
    uri_parts <- s3_split_uri(uri)
    s3()$meta$client$put_object_tagging(
        Bucket = uri_parts$bucket_name,
        Key = uri_parts$key,
        Tagging = list('TagSet' = tag_set)
    )
}
