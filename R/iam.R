#' The default, fork-safe IAM client on the top of \code{botor}
#' @return \code{botocore.client.IAM}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/iam.html}
iam <- function() {
    botor_client('iam', type = 'client')
}


#' Retrieves information about the specified IAM user, including the user's creation date, path, unique ID, and ARN
#' @param ... optional extra arguments passed
#' @return list
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/iam.html#IAM.Client.get_user}
iam_get_user <- function(...) {
    iam()$get_user(...)
}

#' Get the current AWS username
#' @return string
#' @export
#' @seealso \code{\link{sts_whoami}}
iam_whoami <- function() {
    iam_get_user()$User$UserName
}


#' Returns details about the IAM user or role whose credentials are used to call the operation
#' @return \code{list} with \code{UserId}, \code{Account} and \code{Arn}
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/sts.html#STS.Client.get_caller_identity}
#' @export
#' @seealso \code{\link{iam_whoami}}
sts_whoami <- function() {
    botor_client('sts', type = 'client')$get_caller_identity()
}
