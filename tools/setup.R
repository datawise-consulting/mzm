packages <- c("tidyverse",
              "sf",
              "svDialogs",
              "optparse")
new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) {
  install.packages(new_packages)
}
lapply(new_packages, library, character.only=TRUE)
