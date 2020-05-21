#' The default, fork-safe AWS Systems Manager (SSM) client on the top of \code{botor}
#' @return \code{botocore.client.SSM}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ssm.html}
ssm <- function() {
    botor_client('ssm', type = 'client')
}


#' Read AWS System Manager's Parameter Store
#' @param path name/path of the key to be read
#' @param decrypt decrypt the value or return the raw ciphertext
#' @return (optionally decrypted) value
#' @export
ssm_get_parameter <- function(path, decrypt = TRUE) {
    log_trace("Looking up %s in AWS System Manager's Parameter Store", path)
    trypy(ssm()$get_parameter(
        Name = path,
        WithDecryption = decrypt)$Parameter$Value)
}
