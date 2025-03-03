# Function to push a dataset to a Google Sheet
upload_to_google_sheet <- function(
    dataset,                                  # The dataset to upload
    sheet_name = "Listening_to_indonesia",    # Name of the Google Sheet
    tab_name,                                 # Name of the tab
    google_email = "smeets.lsm@gmail.com",    # Email for authentication
    make_public = TRUE,                       # Whether to make the sheet publicly accessible
    use_saved_ids = FALSE,                    # Whether to use previously saved IDs
    save_ids = TRUE,                          # Whether to save IDs for future use
    ids_file = "sheet_ids.rds"                # File to save/load IDs from
) {

  # Validate inputs
  if (missing(dataset)) {
    stop("Dataset is required")
  }

  if (missing(tab_name)) {
    stop("Tab name is required")
  }

  # Check required packages
  required_packages <- c("googlesheets4", "googledrive", "dplyr")
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg)
    }
  }

  # Load libraries
  library(googlesheets4)
  library(googledrive)
  library(dplyr)

  # Authenticate
  drive_auth(email = google_email)
  gs4_auth(token = drive_token())

  # Initialize sheet_id
  sheet_id <- NULL

  # Try to use saved IDs if requested
  if (use_saved_ids && file.exists(ids_file)) {
    saved_ids <- readRDS(ids_file)
    saved_sheet_id <- saved_ids$sheet_id

    # Verify the sheet still exists
    sheet_exists <- tryCatch({
      !is.null(drive_get(as_id(saved_sheet_id)))
    }, error = function(e) {
      return(FALSE)
    })

    if (sheet_exists) {
      sheet_id <- saved_sheet_id
      cat("Using saved sheet ID:", sheet_id, "\n")
    } else {
      cat("Saved sheet ID no longer exists. Will search for or create new sheet.\n")
    }
  }

  # If not using saved IDs or saved ID doesn't exist, search for sheet
  if (is.null(sheet_id)) {
    # Find all sheets with this name
    existing_sheets <- drive_find(
      pattern = sheet_name,
      type = "spreadsheet"
    )

    # If multiple sheets exist, keep only the most recent one and delete others
    if (nrow(existing_sheets) > 0) {
      cat("Found", nrow(existing_sheets), "existing sheets with the name:", sheet_name, "\n")

      # Extract creation time from the nested structure
      creation_times <- sapply(existing_sheets$drive_resource, function(x) x$createdTime)
      existing_sheets$creation_time <- creation_times

      # Sort by creation time (newest first)
      existing_sheets <- existing_sheets %>%
        arrange(desc(creation_time))

      if (nrow(existing_sheets) > 1) {
        # Keep the most recent one, delete the rest
        sheets_to_delete <- existing_sheets[2:nrow(existing_sheets), ]

        for (i in 1:nrow(sheets_to_delete)) {
          drive_trash(as_id(sheets_to_delete$id[i]))
          cat("Deleted duplicate sheet:", sheets_to_delete$name[i], "(ID:", sheets_to_delete$id[i], ")\n")
        }
      }

      # Use the remaining most recent sheet
      sheet_id <- existing_sheets$id[1]
      cat("Using existing sheet:", sheet_name, "(ID:", sheet_id, ")\n")
    } else {
      # No existing sheet, will create new one
      sheet_id <- NULL
      cat("No existing sheet found. Will create a new one.\n")
    }
  }

  # Create or update the sheet
  if (is.null(sheet_id)) {
    # Create a new sheet with the dataset
    new_sheet <- gs4_create(
      name = sheet_name,
      sheets = list(sheet1 = dataset)  # Create with a temporary sheet name
    )
    sheet_id <- as_sheets_id(new_sheet)

    # Rename the first sheet to the desired tab name
    sheet_rename(sheet_id, sheet = 1, new_name = tab_name)
    cat("Created new sheet:", sheet_name, "with tab:", tab_name, "\n")

  } else {
    # Get existing tab names
    existing_tabs <- sheet_names(sheet_id)

    # Update or create the tab
    if (tab_name %in% existing_tabs) {
      # Write new data (overwrites existing data)
      sheet_write(dataset, sheet_id, sheet = tab_name)
      cat("Updated tab '", tab_name, "' with new data\n", sep="")
    } else {
      # Create new tab
      sheet_write(dataset, sheet_id, sheet = tab_name)
      cat("Created new tab '", tab_name, "' with data\n", sep="")
    }
  }

  # Set sharing permissions if requested
  if (make_public) {
    sheet_file <- drive_get(id = sheet_id)
    drive_share(
      file = sheet_file,
      role = "reader",
      type = "anyone"
    )
    cat("\nSheet is now publicly accessible\n")
  }

  # Get the tab properties to find the gid (tab ID)
  tab_properties <- sheet_properties(sheet_id) %>%
    filter(name == tab_name)

  tab_id <- tab_properties$id

  # Create the CSV export URL
  csv_url <- sprintf("https://docs.google.com/spreadsheets/d/%s/export?format=csv&gid=%s",
                     sheet_id,
                     tab_id)

  cat("\nFor tab '", tab_name, "':\n", sep="")
  cat("CSV export URL:", csv_url, "\n")

  # Save the sheet_id and tab_id if requested
  if (save_ids) {
    sheet_id_char <- as.character(sheet_id)
    saveRDS(list(sheet_id = sheet_id_char, tab_id = tab_id), ids_file)
    cat("\nThe sheet ID and tab ID have been saved to '", ids_file, "'.\n", sep="")
    cat("This ensures the CSV URL will remain consistent between runs.\n")
  }

  # Return results
  return(list(
    sheet_id = sheet_id,
    tab_id = tab_id,
    csv_url = csv_url
  ))
}

