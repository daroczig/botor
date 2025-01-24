# botor 0.4.1 (2025-01-23)

Maintenance release:

* Fix S3 listing bug (#18, #20) via #19 (thanks @jburos)
* Support unsigned S3 requests
* Linting and code style updates
* Move CI/CD from Travis to GHA

# botor 0.4.0 (2023-03-12)

* Fix encoding issue of bytearrays
* Python 2 and Python 3 compatibility fixes
* Pass limit param to get records from Kinesis
* Coerce NULL to NA
* Support for AWS Systems Manager

# botor 0.3.0 (2020-02-16)

* Make caching client/resource optional (#7)
* Fix `boto3_version` calling the right object
* S3 taggingfunctions thanks to @katrinabrock (#8)
* Fix S3 URI schema parser (#9 and #10)
* Fix documenting and passing ... in the Kinesis helpers

# botor 0.2 (2019-09-23)

Initial CRAN release.
