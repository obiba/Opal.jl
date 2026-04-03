.authorizationHeader <- function(username, password) {
  paste("X-Opal-Auth", jsonlite::base64_enc(paste(username, password, sep = ":")))
}

.opal.login <- function(username, password, token, url, opts = list(), profile = profile, restore = NULL, context = "r") {
  if (context != "r" && context != "datashield") {
    stop("R session type must be either 'r' or 'datashield'", call. = FALSE)
  }
  if (is.null(url)) stop("opal url is required", call. = FALSE)
  opalUrl <- url
  if (startsWith(url, "http://localhost:")) {
    warning("Connecting through non-secure http", call. = FALSE)
  } else if (startsWith(url, "http://")) {
    stop("Connecting through secure http is required.", call. = FALSE)
  }
  urlObj <- httr::parse_url(opalUrl)

  opal <- new.env(parent = globalenv())
  # Username
  opal$username <- username
  # Strip trailing slash
  opal$url <- sub("/$", "", opalUrl)
  # Domain name
  opal$name <- gsub("[:/].*", "", gsub("http[s]*://", "", opal$url))
  # Version default value
  opal$version <- NA
  # Server response encoding
  opal$encoding <- "UTF-8"
  if (!is.null(opts$encoding)) {
    opal$encoding <- opts$encoding
    opts$encoding <- NULL # not a httr/curl option
  }

  # httr/curl options
  protocol <- strsplit(url, split = "://")[[1]][1]
  options <- opts
  # legacy RCurl options to httr
  if (!is.null(options$ssl.verifyhost)) {
    options$ssl_verifyhost = options$ssl.verifyhost
    options$ssl.verifyhost <- NULL
  }
  if (!is.null(options$ssl.verifypeer)) {
    options$ssl_verifypeer = options$ssl.verifypeer
    options$ssl.verifypeer <- NULL
  }
  if (urlObj$hostname == "localhost") {
    if (is.null(options$ssl_verifyhost)) {
      options$ssl_verifyhost <- FALSE
    }
    if (is.null(options$ssl_verifypeer)) {
      options$ssl_verifypeer <- FALSE
    }
  }

  # authentication strategies
  if(!is.na(username) && !is.null(username) && nchar(username) > 0
     && !is.na(password) && !is.null(password) && nchar(password) > 0) {
    # Authorization header
    opal$authorization <- .authorizationHeader(username, password)
  } else if (!is.na(token) && !is.null(token) && nchar(token) > 0) {
    # Token header
    opal$token <- .tokenHeader(token)
  } else if (!is.null(options$sslcert) && !is.null(options$sslkey)) {
    # Two-way SSL authentication
    if (!is.null(options$cainfo)) {
      options$cainfo <- .getPEMFilePath(options$cainfo)
    }
    options$sslcert <- .getPEMFilePath(options$sslcert)
    options$sslkey <- .getPEMFilePath(options$sslkey)
  } else {
    stop("opal authentication strategy not identified: either provide username/password or API access token or SSL certificate/private keys", call. = FALSE)
  }

  opal$config <- config()
  opal$config$options <- options
  opal$handle <- handle(paste0(opal$url, "/", sample(1000:9999, 1))) # append a random number to ensure urls are different
  opal$rid <- NULL
  opal$restore <- restore
  opal$profile <- profile
  class(opal) <- "opal"

  # get user profile to test sign-in
  profileUrl <- .url(opal, "system", "subject-profile", "_current")
  r <- GET(profileUrl, config = opal$config, httr::add_headers(Authorization = opal$authorization, 'X-Opal-Auth' = opal$token), handle = opal$handle, .verbose())
  if (httr::status_code(r) == 401) {
    headers <- httr::headers(r)
    optHeader <- headers[tolower('WWW-Authenticate')]
    if (optHeader == 'X-Opal-TOTP' || optHeader == 'X-Obiba-TOTP') {
      # TOTP code is required
      code <- readline(prompt = 'Enter 6-digits code: ')
      if (optHeader == 'X-Opal-TOTP')
        r <- GET(profileUrl, config = opal$config, httr::add_headers(Authorization = opal$authorization, 'X-Opal-Auth' = opal$token, 'X-Opal-TOTP' = code), handle = opal$handle, .verbose())
      else
        r <- GET(profileUrl, config = opal$config, httr::add_headers(Authorization = opal$authorization, 'X-Opal-Auth' = opal$token, 'X-Obiba-TOTP' = code), handle = opal$handle, .verbose())
    }
  }
  opal$uprofile <- .handleResponse(opal, r)
  opal$username <- opal$uprofile$principal

  if (isTRUE(opal$uprofile$otpRequired)) {
    warning("Enabling 2FA is required, connect to Opal web page to set up your secret.", call. = FALSE)
  }
  opal$context <- context

  opal
}
