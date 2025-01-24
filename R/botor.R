#' Internal boto3 session
#' @keywords internal
botor_session <- NULL


#' The default, fork-safe Boto3 session
#' @param aws_access_key_id AWS access key ID
#' @param aws_secret_access_key AWS secret access key
#' @param aws_session_token AWS temporary session token
#' @param region_name Default region when creating new connections
#' @param botocore_session Use this Botocore session instead of creating a new default one
#' @param profile_name The name of a profile to use. If not given, then the default profile is used
#' @return boto3 \code{Session}
#' @export
botor <- function(aws_access_key_id, aws_secret_access_key, aws_session_token, region_name, botocore_session, profile_name) {

    mc   <- match.call()
    args <- as.list(mc[-1])

    if (length(args) != 0 || is.null(botor_session) || botor_session_pid() != Sys.getpid()) {

        if (!is.null(botor_session) && length(args) == 0) {
            args <- attr(botor_session, 'args')
        }

        session <- do.call(boto3$session$Session, args)

        utils::assignInMyNamespace(
            'botor_session',
            structure(
                session,
                pid  = Sys.getpid(),
                uuid = uuid(),
                args = args))
    }

    botor_session

}


#' Look up the PID used to initialize the Boto3 session
#' @return int
#' @keywords internal
botor_session_pid <- function() {
    attr(botor_session, 'pid')
}


#' Look up the UUID of the initialized Boto3 session
#' @return int
#' @keywords internal
botor_session_uuid <- function() {
    attr(botor_session, 'uuid')
}


#' boto3 clients cache
#' @keywords internal
clients <- new.env()


#' Creates an initial or reinitialize an already existing AWS client
#' or resource cached in the package's namespace
#' @param service string, eg S3 or IAM
#' @param type AWS service client or resource to be created, eg
#'     \code{s3}
#' @param cache booelan flag for caching the client or resource in the
#'     package namespace. For (internal) package functions, it's best
#'     to set to \code{TRUE} to avoid reinitializing the
#'     client/resource, but for custom use and when you need to use
#'     multiple clients for the same service in parallel (eg working
#'     with different regions etc), you might want to set this to
#'     \code{FALSE}
#' @param ... further parameters passed to the \code{client} or
#'     \code{resource}, eg \code{endpoint_url}
#' @references
#'     \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/core/session.html}
#' @return cached AWS client
#' @importFrom checkmate assert_string assert_flag
#' @export
botor_client <- function(service, type = c('client', 'resource'), cache = TRUE, ...) { # nolint

    assert_string(service)
    assert_flag(cache)
    type <- match.arg(type)

    client <- tryCatch(
        get(service, envir = clients, inherits = FALSE),
        error = function(e) NULL)

    client_params <- list(...)
    if (cache == TRUE && !is.null(client) &&
            attr(client, 'uuid') == botor_session_uuid() &&
            ## compare custom client/resource parameters
            all.equal(client_params, attr(client, 'botor_client_params')) &&
            ## compare serialized configs
            all.equal(client_params$config$`__dict__`, attr(client, 'botor_client_params')$config$`__dict__`)) {
        return(client)
    }

    if (type == 'client') {
        client <- botor()$client(service, ...)
    } else {
        client <- botor()$resource(service, ...)
    }
    attr(client, 'botor_client_params') <- client_params

    if (cache == FALSE) {
        return(client)
    }

    assign(
        x = service,
        value = structure(
            client,
            uuid = botor_session_uuid()),
        envir = clients)
    return(client)

}
