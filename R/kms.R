.kms <- NULL


#' The default, fork-safe KMS client on the top of \code{botor}
#' @return \code{botocore.client.KMS}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kms.html}
kms <- function() {
    botor_client('kms', type = 'client')
}


#' Encrypt plain text via KMS
#' @param key the KMS customer master key identifier as a fully specified Amazon Resource Name (eg \code{arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012}) or an alias with the \code{alias/} prefix (eg \code{alias/foobar})
#' @param text max 4096 bytes long string, eg an RSA key, a database password, or other sensitive customer information
#' @param simplify returns Base64-encoded text instead of raw list
#' @return string or \code{list}
#' @export
#' @seealso kms_decrypt
kms_encrypt <- function(key, text, simplify = TRUE) {
    res <- kms()$encrypt(KeyId = key, Plaintext = charToRaw(text))
    if (simplify == TRUE) {
        res <- res$CiphertextBlob
        res <- base64_enc(res)
    }
    res
}


#' Decrypt cipher into plain text via KMS
#' @param cipher Base64-encoded ciphertext
#' @param simplify returns decrypted plain-text instead of raw list
#' @return decrypted text as string or \code{list}
#' @export
#' @seealso kms_encrypt
kms_decrypt <- function(cipher, simplify = TRUE) {
    res <- kms()$decrypt(CiphertextBlob = base64_dec(cipher))
    if (simplify == TRUE) {
        res <- res$Plaintext
    }
    res
}
