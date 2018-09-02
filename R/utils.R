#' Extract error message from a Python exception
#' @param expression R expression
#' @return error
#' @keywords internal
trypy <- function(expression) {
    tryCatch(
        eval.parent(expression),
        error = function(e) {
            e <- py_last_error()
            stop(paste(e$type, e$value, sep = ': '), call. = FALSE)
        })
}
