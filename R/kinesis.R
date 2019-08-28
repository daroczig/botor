#' The default, fork-safe Kinesis client on the top of \code{botor}
#' @return \code{botocore.client.Kinesis}
#' @export
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html}
kinesis <- function() {
    botor_client('kinesis', type = 'client')
}


#' Describes the specified Kinesis data stream
#' @param stream the name of the stream to describe
#' @export
#' @return list
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Client.describe_stream}
kinesis_describe_stream <- function(stream) {
    kinesis()$describe_stream(StreamName = stream)
}


#' Writes a single data record into an Amazon Kinesis data stream
#' @inheritParams kinesis_describe_stream
#' @param data the data blob (<1 MB) to put into the record, which is base64-encoded when the blob is serialized
#' @param partition_key Unicode string with a maximum length limit of 256 characters determining which shard in the stream the data record is assigned to
#' @param ... optional further parameters that might be required for some of the above parameter combinations
#' @export
#' @return list of \code{ShardId}, \code{SequenceNumber} and \code{EncryptionType}
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Client.put_record}
kinesis_put_record <- function(stream, data, partition_key) {
    kinesis()$put_record(StreamName = stream, Data = data, PartitionKey = partition_key)
}

#' Gets an Amazon Kinesis shard iterator
#' @inheritParams kinesis_put_record
#' @param shard the shard ID of the Kinesis Data Streams shard to get the iterator for
#' @param shard_iterator_type determines how the shard iterator is used to start reading data records from the shard
#' @export
#' @return list of \code{ShardIterator}
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Client.get_shard_iterator}
#' @seealso \code{\link{kinesis_get_records}}
kinesis_get_shard_iterator <- function(stream, shard,
                                       shard_iterator_type = c(
                                           'TRIM_HORIZON', 'LATEST',
                                           'AT_SEQUENCE_NUMBER', 'AFTER_SEQUENCE_NUMBER', 'AT_TIMESTAMP'),
                                       ...) {
    shard_iterator_type <- match.arg(shard_iterator_type)
    kinesis()$get_shard_iterator(StreamName = stream, ShardId = shard, ShardIteratorType = shard_iterator_type)
}

#' Gets data records from a Kinesis data stream's shard
#' @inheritParams kinesis_put_record
#' @param shard_iterator the position in the shard from which you want to start sequentially reading data records, usually provided by \code{\link{kinesis_get_shard_iterator}}
#' @export
#' @return list of \code{Records}, \code{NextShardIterator} and \code{MillisBehindLatest}
#' @references \url{https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/kinesis.html#Kinesis.Client.get_records}
#' @examples \dontrun{
#' botor(profile_name = 'botor-tester')
#' iterator <- kinesis_get_shard_iterator(stream = 'botor-tester', shard = '0')
#' kinesis_get_records(iterator$ShardIterator)
#' }
kinesis_get_records <- function(shard_iterator) {
    kinesis()$get_records(ShardIterator = shard_iterator)
}
