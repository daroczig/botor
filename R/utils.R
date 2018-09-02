#' Extract error message from a Python exception
#' @param expression R expression
#' @return error
#' @keywords internal
#' @examples \dontrun{
#' trypy(botor$resource('foobar'))
#' trypy(sum(1:2))
#' trypy(sum(1:1foo))
#' }
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
