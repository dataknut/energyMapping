library(data.table)
library(skimr)

cert_DT <- data.table::fread("~/Dropbox/data/EW_epc/domestic-E06000045-Southampton/certificates.csv.gz")

names(cert_DT)
skimr::skim(cert_DT)

head(cert_DT[CO2_EMISSIONS_CURRENT > 76])

cert_DT <- data.table::fread("~/data/epc_EW/all-domestic-certificates/domestic-E07000244-East-Suffolk/certificates.csv")

names(cert_DT)
skimr::skim(cert_DT)