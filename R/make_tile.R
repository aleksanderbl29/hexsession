#' Generate tile of package logos
#'
#' @param packages Character vector of package names to include (default: NULL, which uses loaded packages)
#' @param dark_mode Draw the tile on a dark background?
#' @param local_images Optional character vector of local image paths to add to the tile
#' @param local_urls Optional character vector of URLs for each of the local images passed
#' @return Path to the output file
#' @importFrom jsonlite toJSON
#' @importFrom base64enc base64encode
#' @export
make_tile <- function(packages=NULL, local_images=NULL, local_urls=NULL, dark_mode=FALSE) {
  temp_dir <- file.path(getwd(), "temp_hexsession")
  dir.create(temp_dir, showWarnings = FALSE)

  package_data <- get_pkg_data(packages)

  all_logopaths <- c(package_data$logopaths, local_images)
  all_urls <- c(package_data$urls, local_urls)

  if (length(all_urls) < length(all_logopaths)) {
    all_urls <- c(all_urls, rep(NA, length(all_logopaths) - length(all_urls)))
  } else if (length(all_urls) > length(all_logopaths)) {
    all_urls <- all_urls[1:length(all_logopaths)]
  }

  temp_file <- file.path(temp_dir, "package_data.rds")
  saveRDS(list(logopaths = all_logopaths, urls = all_urls), temp_file)

  js_file <- file.path(temp_dir, "hexsession.js")
  generate_hexsession_js(all_logopaths, all_urls, dark_mode, js_file)

  template_path <- system.file("templates", "_hexout.qmd", package = "hexsession")
  file.copy(template_path, file.path(temp_dir, "_hexout.qmd"), overwrite = TRUE)

  quarto_call <- sprintf(
    'quarto render "%s" -P dark_mode:%s',
    file.path(temp_dir, "_hexout.qmd"), tolower(as.character(dark_mode))
  )
  system(quarto_call)

  viewer <- getOption("viewer")
  viewer("temp_hexsession/_hexout.html")
}
