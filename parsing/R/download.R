# Download the source files, convert them to Excel, and prepare file paths of
# the eventual csv files, using year, election and geography.

library(tidyverse)
library(rvest)
library(unpivotr)
library(stringr)
library(here)

sources_path <- here("sources")
xlsx_dir <- here("xlsx")
csv_dir <- here("csv")
idaho_home <- "http://www.sos.idaho.gov/ELECT/results/"
idaho_url <- paste0(idaho_home, "index.html")
url_table_path <- file.path(sources_path, "url-table.html")
working_dir <- here("working")
files_path <- file.path(working_dir, "files.csv")
county_files_path <- file.path(working_dir, "county_files.csv")

cell_text <- function(x) {
  if (is.na(x)) return(NA)
  x <- read_html(x)
  y <- html_nodes(x, xpath = ".//a")
  if (length(y) == 0) {
    return(html_text(x))
  }
  html_text(y)
}

cell_url <- function(x) {
  if (is.na(x)) return(NA)
  x <- read_html(x)
  y <- html_nodes(x, xpath = ".//a")
  if (length(y) == 0) {
    return(html_attr(x, "href"))
  }
  html_attr(y, "href")
}

if (!file.exists(url_table_path)) download.file(idaho_url, url_table_path)

idaho <-
  url_table_path %>%
  xml2::read_html() %>%
  tidy_table() %>%
  .[[3]] %>%
  dplyr::mutate(text = map(html, cell_text),
                url = map(html, cell_url)) %>%
  dplyr::select(-html) %>%
  tidyr::unnest(text, url)

colheader <-
  idaho %>%
  filter(row == 1, text != "") %>%
  rename(colheader = text) %>%
  select(row, col, colheader)

year <-
  idaho %>%
  filter(col == 1, text != "") %>%
  rename(year = text) %>%
  select(row, col, year)

datacells <-
  idaho %>%
  filter(row > 1, col > 1, url != "") %>%
  select(row, col, text, url)

linktable <-
  datacells %>%
  WNW(year) %>%
  NNW(colheader) %>%
  select(year, colheader, text, url)

files <-
  linktable %>%
  # filter(!str_detect(url, "\\.html$")) %>%
  mutate(year_date = paste0(year, "0101"),
         meta = tolower(paste(colheader, text)),
         scope = tolower(text),
         election = str_extract(meta, "primary*|general*"),
         geography = str_extract(meta, "county*|precinct*"),
         url = paste0(idaho_home, url),
         basename = basename(url),
         source_dir = file.path(sources_path, year),
         source_path = file.path(source_dir, basename),
         xlsx_dir = file.path(xlsx_dir, year),
         xlsx_path = file.path(xlsx_dir, str_replace(basename, "xls$", "xlsx")),
         csv_path = file.path(csv_dir,
                              paste0(paste(year_date,
                                           "id",
                                           election,
                                           geography,
                                           sep = "__"),
                                     ".csv"))) %>%
  select(-colheader, -text, -meta)

# Download all the files, if not already present
download_source <- function(url, source_dir, source_path) {
  if (!file.exists(source_path)) {
    dir.create(source_dir, showWarnings = FALSE, recursive = TRUE)
    download.file(url, source_path)
  }
}

files %>%
  {pwalk(list(.$url, .$source_dir, .$source_path), download_source)}

county_files <-
  files %>%
  select(-xlsx_dir) %>%
  filter(str_detect(url, "\\.html$")) %>%
  select(-url) %>%
  mutate(html = map(source_path,
                    ~ .x %>%
                      read_html() %>%
                      tidy_table() %>%
                      .[[2]] %>%
                      .$html %>% # The table is nested inside another table
                      read_html() %>%
                        tidy_table() %>%
                        .[[2]] %>%
                        dplyr::mutate(url = map(html, cell_url)) %>%
                        dplyr::select(-html) %>%
                        tidyr::unnest(url) %>%
                        select(url))) %>%
  unnest(html) %>%
  # Make new filenames for these county files
  mutate(url = paste0(idaho_home, year, "/", url),
         basename = basename(url),
         source_dir = file.path(sources_path,
                                year,
                                "county"),
         source_path = file.path(source_dir, basename),
         xlsx_dir = file.path(xlsx_dir, year, "county", election),
         xlsx_path = file.path(xlsx_dir, str_replace(basename, "xls$", "xlsx")),
         csv_path = file.path(csv_dir,
                              paste0(paste(year_date,
                                           "id",
                                           election,
                                           geography,
                                           sep = "__"),
                                     ".csv"))) %>%
  select(!!! rlang::syms(colnames(files))) # Restore the order of colnames

# Download all the county files, if not already present
county_files %>%
  {pwalk(list(.$url, .$source_dir, .$source_path), download_source)}

# Convert all xls files to xlsx, and put all xlsx files into the xlsx directory
xls2xlsx <- function(source_path, xlsx_dir, xlsx_path) {
  cat(source_path, " : ", xlsx_path, "\n")
  if (!file.exists(xlsx_path)) {
    if (str_detect(source_path, "\\.xlsx$")) {
      file.copy(source_path, xlsx_path)
    } else {
      system(paste("libreoffice --convert-to xlsx --outdir", xlsx_dir, source_path))
    }
  }
}

files %>%
  filter(!str_detect(url, "\\.html$")) %>%
  {pwalk(list(.$source_path, .$xlsx_dir, .$xlsx_path), xls2xlsx)}

county_files %>%
  {pwalk(list(.$source_path, .$xlsx_dir, .$xlsx_path), xls2xlsx)}

# Save the tables of files, filenames etc.
dir.create(working_dir, showWarnings = FALSE, recursive = TRUE)
write_csv(files, files_path)
write_csv(county_files, county_files_path)
