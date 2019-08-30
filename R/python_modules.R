python_modules <- new.env()
python_builtins <- NULL

#' Imports and caches a Python module
#' @param module a Python module name
#' @return imported Python module
#' @keywords internal
require_python_module <- function(module) {

    tryCatch(
        get(module, envir = python_modules, inherits = FALSE),
        error = function(e) {
            loaded_module <- import(module = module)
            assign(x = module, value = loaded_module, envir = python_modules)
            loaded_module
        })

}

#' Imports and caches a Python module
#' @return imported Python module
#' @keywords internal
require_python_builtins <- function() {
    utils::assignInMyNamespace(
        'python_builtins',
        reticulate::import_builtins())
    python_builtins
}
