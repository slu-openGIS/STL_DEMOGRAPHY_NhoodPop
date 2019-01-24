unique_id <- function(x, ...) {
  id_set <- x %>% select(...)
  id_set_dist <- id_set %>% distinct
  if (nrow(id_set) == nrow(id_set_dist)) {
    TRUE
  } else {
    non_unique_ids <- id_set %>% 
      filter(id_set %>% duplicated()) %>% 
      distinct()
    suppressMessages(
      inner_join(non_unique_ids, x) %>% arrange(...)
    )
  }
}

# source - https://edwinth.github.io/blog/unique_id/