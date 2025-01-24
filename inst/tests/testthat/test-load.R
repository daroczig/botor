library(botor)
library(testthat)

context('s3')

## https://aws.amazon.com/marketplace/pp/prodview-zpajhdz2eccoo
pubs3 <- file.path(
    's3://pansurg-curation-raw-open-data/cwtest/SampleDataDuplBookmark/upload_date=1589299981',
    'debabrata_7a7b6d77-d101-457c-a3c2-77c8f1f50a5e_1589299981_uploadfiles_1589299981.csv'
)
## need to disable signing for these public objects
options_backup <- getOption('botor-s3-disable-signing')
options('botor-s3-disable-signing' = TRUE)

test_that('load data from s3', {
    expect_true(s3_exists(pubs3))
    expect_error(s3_read(pubs3, read.csv), NA)
})

options('botor-s3-disable-signing' = options_backup)
