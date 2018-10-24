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

    assert_boto3_available()

    mc   <- match.call()
    args <- as.list(mc[-1])
    if (length(args) != 0 || is.null(botor_session) || botor_session_pid() != Sys.getpid()) {


        ## TODO use previous botor's args if pid doesn't match
        session <- do.call(boto3$Session, args)

        utils::assignInMyNamespace(
            'botor_session',
            structure(
                session,
                id   = reticulate:::py_id(session),
                pid  = Sys.getpid(),
                args = args))
    }

    botor_session

}


#' Look up internal Python id of the Boto3 session
#' @return int
#' @keywords internal
botor_session_id <- function() {
    attr(botor_session, 'id')
}


#' Look up the PID used to initialize the Boto3 session
#' @return int
#' @keywords internal
botor_session_pid <- function() {
    attr(botor_session, 'pid')
}
