#' Extract error message from a Python exception
#' @param expression R expression
#' @return error
#' @keywords internal
#' @examples \dontrun{
#' trypy(botor()$resource('foobar'))
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
    as.character(require_python_module('base64')$b64encode(text))
}


#' Base64-decode a string into raw bytes using Python's base64 module
#' @param text string
#' @return \code{raw} bytes
#' @keywords internal
#' @examples \dontrun{
#' botor:::base64_dec(botor:::base64_enc(charToRaw('foobar')))
#' }
#' @seealso \code{\link{base64_enc}}
#' @importFrom reticulate import
base64_dec <- function(text) {
    assert_string(text)
    require_python_builtins()$bytearray(require_python_module('base64')$b64decode(text))
}


#' Generate UUID using Python's uuid module
#' @return string
#' @keywords internal
#' @importFrom reticulate py_str
uuid <- function() {
    py_str(require_python_module('uuid')$uuid1())
}


#' Guess the type of a file based on the filename using \code{mimetypes} Python module
#' @param file path
#' @return string
#' @export
#' @importFrom reticulate import
mime_guess <- function(file) {

    content_type <- require_python_module('mimetypes')$guess_type(file)[[1]]

    ## return NA instead of NULL
    if (is.null(content_type)) {
        content_type <- NA
    }

    content_type

}


#' Transforms a python2 string literal or python3 bytes literal into an R string
#'
#' This is useful to call eg for the KMS call, where python2 returns a string, but python3 returns bytes literals -- calling "decode" is tricky, but bytearray conversion, then passing the raw vector to R and converting that a string works.
#' @param x string
#' @return string
#' @keywords internal
coerce_bytes_literals_to_string <- function(x) {
    rawToChar(require_python_builtins()$bytearray(x))
}
