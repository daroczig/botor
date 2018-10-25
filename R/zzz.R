clients <- new.env()

.onLoad <- function(libname, pkgname) {

    utils::assignInMyNamespace(
        'boto3',
        reticulate::import(
            module = 'boto3',
            delay_load = list(
                on_error = function(e) stop(e$message)
            )))

    ## options('reticulate.traceback' = FALSE)

}
