#' Extract error message from a Python exception
#' @param expression R expression
#' @return error
#' @keywords internal
trypy <- function(expression) {
    tryCatch(
        eval.parent(expression),
        error = function(e) {
            e$call <- sys.calls()[[sys.nframe() - 5]]
            stop(e)
        })
}
