#' Raw access to the boto3 module
#' @export
botor <- NULL

.onLoad <- function(libname, pkgname) {

    utils::assignInMyNamespace(
        'botor',
        reticulate::import('boto3', delay_load = TRUE))

}


#' Checks if boto3 Python module is installed
#' @return boolean
#' @export
#' @importFrom reticulate py_module_available
boto3_available <- function() {
    py_module_available('boto3')
}


#' Fails if boto3 Python module is not installed
#' @export
assert_boto3_available <- function() {
    if (boto3_available() == FALSE) {
        stop('boto3 not available, please install manually or via reticulate::py_install')
    }
}
