.onLoad <- function(libname, pkgname) {

    utils::assignInMyNamespace(
        'boto3',
        reticulate::import('boto3'))

    ## options('reticulate.traceback' = FALSE)

}
