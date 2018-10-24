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
#' @param raw \code{raw} bytes
#' @return string
#' @export
#' @seealso \code{\link{base64_dec}}
base64_enc <- function(raw) {
    import('base64')$b64encode(raw)
}


#' Base64-decode a string into raw bytes using Python's base64 module
#' @param text string
#' @return \code{raw} bytes
#' @export
#' @examples \dontrun{
#' base64_dec(base64_enc(charToRaw('foobar')))
#' }
#' @seealso \code{\link{base64_enc}}
base64_dec <- function(text) {
    import('base64')$b64decode(text)
}


#' Generate UUID using Python's uuid module
#' @return string
#' @export
#' @importFrom reticulate py_str
uuid <- function() {
    py_str(import('uuid')$uuid1())
}
