#' Raw access to the boto3 module
#' @export
botor <- NULL

.onLoad <- function(libname, pkgname) {

    utils::assignInMyNamespace(
        'botor',
        reticulate::import('boto3', delay_load = TRUE))

    ## options('reticulate.traceback' = FALSE)

}
