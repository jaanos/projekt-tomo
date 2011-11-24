regex_break <- function(whole_regex, regexes, source) {
    whole_matches <- gregexpr(paste("(?sm)", whole_regex, sep=""), source, perl=TRUE)[[1]]
    whole_matches <- mapply(
        function(start, end) substr(source, start, end),
        whole_matches,
        whole_matches + attr(whole_matches, "match.length") - 1
    )
    m <- length(whole_matches)
    n <- length(regexes)
    matches <- matrix("", nrow=m, ncol=n)
    for (i in 1:m) {
        whole <- whole_matches[i]
        for (j in 1:length(regexes)) {
            rest_regex <- paste(regexes[-(1 : j)], collapse="")
            part_regex <- paste("(?sm)\\A", regexes[j], "(?=", rest_regex, "\\Z)", sep="")
            match <- regexpr(part_regex, whole, perl=TRUE)
            end <- attr(match, "match.length")
            matches[i, j] <- substr(whole, 1, end)
            whole <- substr(whole, end + 1, nchar(whole))
        }
    }
    matches
}

strip <- function(str) gsub("^\\s+|\\s+$", "", str)
rstrip <- function(str) gsub("\\s+$", "", str)

super_strip <- function(str) {
    str <- gsub("(^|\n)# ?", "\n", str)
    str <- gsub("\\A\\s+|\\s+\\Z", "", str, perl=TRUE)
}

get_current_filename <- function () {
  if (length(showConnections()) > 1) {
    return(showConnections()[1, "description"])
  } else {
    return(Find(Negate(is.null), Map(function(f) { f$ofile }, sys.frames()), right=TRUE))
  }
}

postJSON <-function(host, path, port=80, json) {
  con <- socketConnection(host=host, port=port, server=FALSE, blocking=TRUE)
  post <- paste(
    "POST ", path, " HTTP/1.1\r\n",
    "Host: ", host, "\r\n",
    "Connection: close\r\n",
    "Content-Type: application/json; charset=utf-8\r\n",
    "Content-Length: ", nchar(json, type="bytes"), "\r\n\r\n",
    json,
    sep = ""
  )
  writeLines(post, con=con, sep="", useBytes=TRUE)
  response <- paste(readLines(con, warn=FALSE), collapse="\r\n")
  close.connection(con)
  Encoding(response) <- "UTF-8"

  header <- sub("\r\n\r\n.*?$", "", response)
  if(grepl("Transfer-Encoding: chunked", header)) {
    chunked <- sub("^.*?\r\n\r\n", "", response)
    contents <- ""
    repeat {
      match <- regex_break(".*", c("[a-f0-9]+", "\\r\\n", ".*"), chunked)
      len <- strtoi(match[1, 1], 16)
      rest <- match[1, 3]
      if(len == 0 || ncol(match) == 0)
        break
      contents <- paste(contents, substr(rest, 1, len), sep = "")
      chunked <- substr(rest, len + 2, nchar(rest))
    }
  } else {
    contents <- sub("^.*?\r\n\r\n", "", response)
  }
  return(contents)
}

