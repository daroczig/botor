.kms <- NULL


#' The default, fork-safe KMS client on the top of \code{botor}
#' @return \code{s3.ServiceResource}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html#service-resource}
kms <- function() {
    if (is.null(.kms) || attr(.kms, 'uuid') != botor_session_uuid()) {
        flog.warn('UPDATE S3')
        flog.info(botor()$region_name)
        utils::assignInMyNamespace('.kms', structure(
            botor()$client('kms'),
            uuid = botor_session_uuid()))
    }
    .kms
}


#' Encrypt plain text via KMS
#' @param key the KMS customer master key identifier as a fully specified Amazon Resource Name (eg \code{arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012}) or an alias with the \code{alias/} prefix (eg \code{alias/foobar})
#' @param text max 4096 bytes long string, eg an RSA key, a database password, or other sensitive customer information
#' @param simplify returns Base64-encoded text instead of raw list
#' @return list or string
#' @export
kms_encrypt <- function(key, text, simplify = TRUE) {
    res <- kms()$encrypt(KeyId = key, Plaintext = charToRaw(text))
    if (simplify == TRUE) {
        res <- res$CiphertextBlob
        res <- base64_enc(res)
    }
    res
}
