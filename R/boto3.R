#' Check if boto3 Python module is installed
#' @return boolean
#' @export
#' @importFrom reticulate py_module_available
boto3_available <- function() {
    py_available() & py_module_available('boto3')
}


#' Fail if boto3 Python module is not installed
#' @keywords internal
assert_boto3_available <- function() {
    if (boto3_available() == FALSE) {
        stop('boto3 not available, please install manually or via reticulate::py_install')
    }
}


#' boto3 version
#' @return string
#' @export
boto3_version <- function() {
    botor$`__version__`
}
