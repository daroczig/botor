#' Extract error message from a Python exception
#' @param expression R expression
#' @return error
#' @keywords internal
#' @examples \dontrun{
#' trypy(botor$resource('foobar'))
#' trypy(sum(1:2))
#' trypy(sum(1:1foo))
#' }
#' @importFrom reticulate py_clear_last_error py_last_error
trypy <- function(expression) {
    py_clear_last_error()
    tryCatch(
    eval.parent(expression),
    error = function(e) {
        e$call <- sys.calls()[[1]]
        if (sys.nframe() > 5) {
            e$call <- sys.calls()[[sys.nframe() - 5]]
        }
        pe <- py_last_error()
        if (!is.null(pe)) {
            e$message <- paste0('Python `', pe$type, '`: ', pe$value)
        }
        stop(e)
    })
}


#' Base64-encode raw bytes using Python's base64 module
#' @param text \code{raw}, R string or Python string
#' @return string
#' @keywords internal
#' @seealso \code{\link{base64_dec}}
#' @importFrom checkmate assert_class
base64_enc <- function(text) {
    as.character(import('base64')$b64encode(text))
}


#' Base64-decode a string into raw bytes using Python's base64 module
#' @param text string
#' @return \code{raw} bytes
#' @keywords internal
#' @examples \dontrun{
#' base64_dec(base64_enc(charToRaw('foobar')))
#' }
#' @seealso \code{\link{base64_enc}}
#' @importFrom reticulate import
base64_dec <- function(text) {
    assert_string(text)
    import('base64')$b64decode(text)
}


#' Generate UUID using Python's uuid module
#' @return string
#' @keywords internal
#' @importFrom reticulate py_str
uuid <- function() {
    py_str(import('uuid')$uuid1())
}


#' Creates an initial or reinitialize an already existing AWS client or resource
#' @param service string, eg S3 or IAM
#' @param type client or resource to be created
#' @return cached AWS client
#' @keywords internal
botor_client <- function(service, type = c('client', 'resource')) {
    assert_string(service)
    type <- match.arg(type)
    .name  <- paste0('.', service)
    client <- getFromNamespace(.name, 'botor')
    if (is.null(client) || attr(client, 'uuid') != botor_session_uuid()) {
        if (type == 'client') {
            client <- botor()$client(service)
        } else {
            client <- botor()$resource(service)
        }
        utils::assignInMyNamespace(.name, structure(
            client,
            uuid = botor_session_uuid()))
    }
    client
}
