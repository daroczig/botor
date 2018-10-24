#' Internal boto3 session
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
botor <- function(aws_access_key_id, aws_secret_access_key, aws_session_token,
                  region_name, botocore_session, profile_name) {

    mc   <- match.call()
    args <- as.list(mc[-1])

    if (length(args) != 0 || is.null(botor_session) || botor_session_pid() != Sys.getpid()) {

        if (!is.null(botor_session) & length(args) == 0) {
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
