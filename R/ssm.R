#' The default, fork-safe AWS Systems Manager (SSM) client on the top of \code{botor}
#' @return \code{botocore.client.SSM}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ssm.html}
ssm <- function() {
    botor_client('ssm', type = 'client')
}


#' Read AWS System Manager's Parameter Store
#' @param path name/path of the key to be read
#' @return decrypted value
#' @export
ssm_get_parameter <- function(path, decrypt = TRUE) {
    trypy(ssm()$get_parameter(
        Name = path,
        WithDecryption = decrypt)$Parameter$Value)
}
