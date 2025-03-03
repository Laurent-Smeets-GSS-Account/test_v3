food_security_prep <- function(data) {
  # Define the food insecurity variables from original survey
  food_vars <- c("wb24", "wb25", "wb26", "wb27", "wb28", "wb29", "wb30", "wb31")

  # Create binary variables where 1=yes, 0=no
  data %>%
    dplyr::mutate(
      # Create binary versions of all food security variables
      dplyr::across(
        all_of(food_vars),
        ~ case_when(
          . == 1 ~ 1,  # Original value 1 (yes) stays as 1
          . == 2 ~ 0,  # Original value 2 (no) becomes 0
          TRUE ~ NA_real_  # Missing values stay missing
        ),
        .names = "bin_{.col}"
      )
    ) %>%
    # Rename the binary variables to more descriptive names
    dplyr::rename(
      worried = bin_wb24,
      unhealthy = bin_wb25,
      low_diversity = bin_wb26,
      skip_meal = bin_wb27,
      eat_less = bin_wb28,
      ran_out = bin_wb29,
      went_hungry = bin_wb30,
      whole_day = bin_wb31
    ) %>%
    # Create total food insecurity score as sum of all indicators
    dplyr::mutate(
      totfoodinsec = rowSums(
        dplyr::select(., worried, unhealthy, low_diversity, skip_meal,
                      eat_less, ran_out, went_hungry, whole_day),
        na.rm = TRUE
      )
    )
}

# Function to extract variables from a formula
extract_vars_from_formula <- function(formula_obj) {
  # Convert formula to character
  formula_str <- as.character(formula_obj)

  # Get variables from both sides
  vars <- c()

  # Left-hand side (dependent variable)
  if (length(formula_str) >= 2) {
    vars <- c(vars, formula_str[2])
  }

  # Right-hand side (independent variables)
  if (length(formula_str) >= 3) {
    # Parse the right side to extract variable names
    rhs <- formula_str[3]

    # Remove function calls like i() and handle + operators
    rhs_vars <- unlist(strsplit(rhs, " \\+ "))
    rhs_vars <- gsub("i\\(([^)]+)\\)", "\\1", rhs_vars) # Remove i() function

    vars <- c(vars, rhs_vars)
  }

  # Return unique variables
  return(unique(vars))
}

# Create weighted quintiles function to replicate Stata's xtile with weights
stata_weighted_quantile <- function(x, weights, probs = seq(0, 1, 0.2)) {
  # Remove NA values
  valid <- !is.na(x) & !is.na(weights)
  x <- x[valid]
  weights <- weights[valid]

  # Sort data by x
  ord <- order(x)
  x <- x[ord]
  weights <- weights[ord]

  # Calculate cumulative weights
  cum_weights <- cumsum(weights) / sum(weights)

  # Find points corresponding to requested quantiles
  result <- numeric(length(probs))
  for (i in seq_along(probs)) {
    if (probs[i] <= 0) {
      result[i] <- min(x)
    } else if (probs[i] >= 1) {
      result[i] <- max(x)
    } else {
      # Find the appropriate value for this probability
      idx <- which(cum_weights >= probs[i])[1]
      result[i] <- x[idx]
    }
  }

  return(result)
}

# Function to create Stata-style weighted quintiles
stata_weighted_ntile <- function(x, weights, n = 5) {
  # Get quantile breaks
  probs <- seq(0, 1, 1/n)
  breaks <- stata_weighted_quantile(x, weights, probs)

  # Assign values to quintiles
  result <- cut(x,
                breaks = unique(breaks),
                labels = FALSE,
                include.lowest = TRUE)

  return(result)
}


