///|
/// whenwords - A relative time formatting library
/// MoonBit implementation following the whenwords specification v0.1.0

// Time constants in seconds
let seconds_per_minute : Int64 = 60

///|
let seconds_per_hour : Int64 = 3600

///|
let seconds_per_day : Int64 = 86400

///|
let seconds_per_month : Int64 = 2592000 // 30 days

///|
let seconds_per_year : Int64 = 31536000 // 365 days

///|
/// Converts a timestamp to a relative time string like "3 hours ago" or "in 2 days"
///
/// Parameters:
/// - timestamp: Unix timestamp in seconds
/// - reference: Reference timestamp (defaults to current context, must be provided)
///
/// Returns: Human-readable relative time string
pub fn timeago(timestamp : Int64, reference~ : Int64) -> String {
  let diff = reference - timestamp
  let abs_diff = if diff < 0L { -diff } else { diff }
  let is_future = diff < 0L
  let result = format_time_diff(abs_diff)
  if is_future {
    if result == "just now" {
      "just now"
    } else {
      "in " + strip_ago_suffix(result)
    }
  } else {
    result
  }
}

///|
fn strip_ago_suffix(s : String) -> String {
  if s.has_suffix(" ago") {
    s.unsafe_substring(start=0, end=s.length() - 4)
  } else {
    s
  }
}

///|
fn format_time_diff(seconds : Int64) -> String {
  // 0-44 seconds: "just now"
  if seconds < 45L {
    return "just now"
  }
  // 45-89 seconds: "1 minute ago"
  if seconds < 90L {
    return "1 minute ago"
  }
  // 90 sec - 44 min: "{n} minutes ago"
  if seconds < 45L * 60L {
    let minutes = round_half_up(seconds, seconds_per_minute)
    return pluralize(minutes, "minute") + " ago"
  }
  // 45-89 minutes: "1 hour ago"
  if seconds < 90L * 60L {
    return "1 hour ago"
  }
  // 90 min - 21 hours: "{n} hours ago"
  if seconds < 22L * 3600L {
    let hours = round_half_up(seconds, seconds_per_hour)
    return pluralize(hours, "hour") + " ago"
  }
  // 22-35 hours: "1 day ago"
  if seconds < 36L * 3600L {
    return "1 day ago"
  }
  // 36 hours - 25 days: "{n} days ago"
  if seconds < 26L * 86400L {
    let days = round_half_up(seconds, seconds_per_day)
    return pluralize(days, "day") + " ago"
  }
  // 26-45 days: "1 month ago"
  if seconds < 46L * 86400L {
    return "1 month ago"
  }
  // 46-319 days: "{n} months ago"
  if seconds < 320L * 86400L {
    let months = round_half_up(seconds, seconds_per_month)
    return pluralize(months, "month") + " ago"
  }
  // 320-547 days: "1 year ago"
  if seconds < 548L * 86400L {
    return "1 year ago"
  }
  // 548+ days: "{n} years ago"
  let years = round_half_up(seconds, seconds_per_year)
  pluralize(years, "year") + " ago"
}

///|
fn round_half_up(value : Int64, divisor : Int64) -> Int64 {
  (value + divisor / 2L) / divisor
}

///|
fn pluralize(count : Int64, unit : String) -> String {
  if count == 1L {
    "1 " + unit
  } else {
    count.to_string() + " " + unit + "s"
  }
}

///|
/// Options for duration formatting
pub(all) struct DurationOptions {
  compact : Bool // Use compact format like "2h 30m"
  max_units : Int // Maximum number of units to display (default: 2)
}

///|
pub fn DurationOptions::default() -> DurationOptions {
  { compact: false, max_units: 2 }
}

///|
/// Formats a number of seconds as a human-readable duration
///
/// Parameters:
/// - seconds: Non-negative number of seconds
/// - options: Formatting options (compact mode, max units)
///
/// Returns: Human-readable duration string
pub fn duration(
  seconds : Int64,
  options? : DurationOptions = DurationOptions::default(),
) -> String {
  if seconds == 0L {
    return if options.compact { "0s" } else { "0 seconds" }
  }
  let mut remaining = seconds
  let parts : Array[String] = []
  // Years
  if remaining >= seconds_per_year {
    let years = remaining / seconds_per_year
    remaining = remaining % seconds_per_year
    parts.push(format_duration_unit(years, "year", options.compact))
  }
  // Months
  if remaining >= seconds_per_month && parts.length() < options.max_units {
    let months = remaining / seconds_per_month
    remaining = remaining % seconds_per_month
    parts.push(format_duration_unit(months, "month", options.compact))
  }
  // Days
  if remaining >= seconds_per_day && parts.length() < options.max_units {
    let days = remaining / seconds_per_day
    remaining = remaining % seconds_per_day
    parts.push(format_duration_unit(days, "day", options.compact))
  }
  // Hours
  if remaining >= seconds_per_hour && parts.length() < options.max_units {
    let hours = remaining / seconds_per_hour
    remaining = remaining % seconds_per_hour
    parts.push(format_duration_unit(hours, "hour", options.compact))
  }
  // Minutes
  if remaining >= seconds_per_minute && parts.length() < options.max_units {
    let minutes = remaining / seconds_per_minute
    remaining = remaining % seconds_per_minute
    parts.push(format_duration_unit(minutes, "minute", options.compact))
  }
  // Seconds (only if we have room and there are remaining seconds)
  if remaining > 0L && parts.length() < options.max_units {
    parts.push(format_duration_unit(remaining, "second", options.compact))
  }
  // Handle case where all units are zero but we have remaining seconds
  if parts.is_empty() {
    parts.push(format_duration_unit(remaining, "second", options.compact))
  }
  if options.compact {
    parts.join(" ")
  } else {
    parts.join(", ")
  }
}

///|
fn format_duration_unit(count : Int64, unit : String, compact : Bool) -> String {
  if compact {
    let abbrev = match unit {
      "year" => "y"
      "month" => "mo"
      "day" => "d"
      "hour" => "h"
      "minute" => "m"
      "second" => "s"
      _ => unit
    }
    count.to_string() + abbrev
  } else {
    pluralize(count, unit)
  }
}

///|
/// Error type for parse_duration
pub suberror ParseDurationError {
  ParseDurationError(String)
}

///|
/// Parses a duration string into seconds
///
/// Supported formats:
/// - Compact: "2h30m", "2h 30m"
/// - Verbose: "2 hours 30 minutes", "2 hours and 30 minutes"
/// - Decimal: "2.5 hours", "1.5h"
/// - Colon: "2:30" (h:mm), "2:30:00" (h:mm:ss)
///
/// Returns: Number of seconds, or error if parsing fails
pub fn parse_duration(input : String) -> Int64 raise ParseDurationError {
  let s = input.trim().to_string()
  if s.is_empty() {
    raise ParseDurationError("Empty input")
  }
  // Try colon notation first: "2:30" or "2:30:00"
  if s.contains(":") {
    return parse_colon_duration(s)
  }
  // Parse compact/verbose format
  parse_unit_duration(s)
}

///|
fn parse_colon_duration(s : String) -> Int64 raise ParseDurationError {
  let parts : Array[String] = s
    .split(":")
    .map(fn(sv) { sv.to_string() })
    .collect()
  match parts.length() {
    2 => {
      let hours = parse_int64_safe(parts[0])
      let minutes = parse_int64_safe(parts[1])
      hours * seconds_per_hour + minutes * seconds_per_minute
    }
    3 => {
      let hours = parse_int64_safe(parts[0])
      let minutes = parse_int64_safe(parts[1])
      let secs = parse_int64_safe(parts[2])
      hours * seconds_per_hour + minutes * seconds_per_minute + secs
    }
    _ => raise ParseDurationError("Invalid colon notation")
  }
}

///|
fn parse_int64_safe(s : String) -> Int64 raise ParseDurationError {
  let trimmed = s.trim()
  @strconv.parse_int64(trimmed) catch {
    _ => raise ParseDurationError("Invalid number: " + trimmed.to_string())
  }
}

///|
fn parse_float64_safe(s : String) -> Double raise ParseDurationError {
  let trimmed = s.trim()
  @strconv.parse_double(trimmed) catch {
    _ => raise ParseDurationError("Invalid number: " + trimmed.to_string())
  }
}

///|
fn parse_unit_duration(s : String) -> Int64 raise ParseDurationError {
  // Remove "and", ",", extra spaces
  let normalized = s
    .to_lower()
    .replace_all(old=",", new=" ")
    .replace_all(old=" and ", new=" ")
  let mut total_seconds = 0.0
  let mut current_num = ""
  let mut i = 0
  let chars = normalized.to_array()
  while i < chars.length() {
    let c = chars[i]
    // Accumulate digits and decimal points
    if (c >= '0' && c <= '9') || c == '.' {
      current_num = current_num + c.to_string()
      i = i + 1
      continue
    }
    // Skip whitespace between number and unit
    if c == ' ' && current_num.is_empty() {
      i = i + 1
      continue
    }
    // Try to parse a unit
    if not(current_num.is_empty()) || c != ' ' {
      // Find the unit
      let unit_start = i
      while i < chars.length() &&
            chars[i] != ' ' &&
            not(chars[i] >= '0' && chars[i] <= '9') {
        i = i + 1
      }
      if unit_start < i {
        let unit = normalized.unsafe_substring(start=unit_start, end=i)
        if not(current_num.is_empty()) {
          let num = parse_float64_safe(current_num)
          let multiplier = unit_to_seconds(unit)
          if multiplier == 0L {
            raise ParseDurationError("Unknown unit: " + unit)
          }
          total_seconds = total_seconds + num * multiplier.to_double()
          current_num = ""
        }
      }
    }
    if i < chars.length() && chars[i] == ' ' {
      i = i + 1
    }
  }
  // Handle trailing number without unit (assume seconds)
  if not(current_num.is_empty()) {
    let num = parse_float64_safe(current_num)
    total_seconds = total_seconds + num
  }
  if total_seconds < 0.0 {
    raise ParseDurationError("Negative duration")
  }
  total_seconds.to_int64()
}

///|
fn unit_to_seconds(unit : String) -> Int64 {
  match unit {
    "s" | "sec" | "second" | "seconds" => 1L
    "m" | "min" | "minute" | "minutes" => seconds_per_minute
    "h" | "hr" | "hour" | "hours" => seconds_per_hour
    "d" | "day" | "days" => seconds_per_day
    "w" | "wk" | "week" | "weeks" => 7L * seconds_per_day
    "mo" | "month" | "months" => seconds_per_month
    "y" | "yr" | "year" | "years" => seconds_per_year
    _ => 0L
  }
}

///|
/// Date information extracted from a Unix timestamp
priv struct DateInfo {
  year : Int
  month : Int // 1-12
  day : Int // 1-31
  weekday : Int // 0=Sunday, 1=Monday, ..., 6=Saturday
}

///|
fn timestamp_to_date(timestamp : Int64) -> DateInfo {
  // Convert Unix timestamp to date components
  // Days since Unix epoch (1970-01-01)
  let days = timestamp / seconds_per_day
  // Calculate weekday (1970-01-01 was Thursday = 4)
  let weekday = ((days % 7L).to_int() + 4) % 7
  // Calculate year, month, day using a simplified algorithm
  let mut remaining_days = days.to_int()
  let mut year = 1970
  // Advance by years
  while true {
    let days_in_year = if is_leap_year(year) { 366 } else { 365 }
    if remaining_days < days_in_year {
      break
    }
    remaining_days = remaining_days - days_in_year
    year = year + 1
  }
  // Advance by months
  let mut month = 1
  while month <= 12 {
    let days_in_month = get_days_in_month(year, month)
    if remaining_days < days_in_month {
      break
    }
    remaining_days = remaining_days - days_in_month
    month = month + 1
  }
  let day = remaining_days + 1
  { year, month, day, weekday }
}

///|
fn is_leap_year(year : Int) -> Bool {
  year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
}

///|
fn get_days_in_month(year : Int, month : Int) -> Int {
  match month {
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    4 | 6 | 9 | 11 => 30
    2 => if is_leap_year(year) { 29 } else { 28 }
    _ => 30
  }
}

///|
fn weekday_name(weekday : Int) -> String {
  match weekday {
    0 => "Sunday"
    1 => "Monday"
    2 => "Tuesday"
    3 => "Wednesday"
    4 => "Thursday"
    5 => "Friday"
    6 => "Saturday"
    _ => "Unknown"
  }
}

///|
fn month_name(month : Int) -> String {
  match month {
    1 => "January"
    2 => "February"
    3 => "March"
    4 => "April"
    5 => "May"
    6 => "June"
    7 => "July"
    8 => "August"
    9 => "September"
    10 => "October"
    11 => "November"
    12 => "December"
    _ => "Unknown"
  }
}

///|
/// Returns a contextual date string like "Today", "Yesterday", "Last Tuesday", or "March 5"
///
/// Parameters:
/// - timestamp: Unix timestamp in seconds
/// - reference: Reference timestamp for comparison
///
/// Returns: Human-readable date string
pub fn human_date(timestamp : Int64, reference~ : Int64) -> String {
  let target = timestamp_to_date(timestamp)
  let ref_date = timestamp_to_date(reference)
  // Calculate day difference
  let target_days = timestamp / seconds_per_day
  let ref_days = reference / seconds_per_day
  let day_diff = (ref_days - target_days).to_int()
  // Same day
  if day_diff == 0 {
    return "Today"
  }
  // Yesterday
  if day_diff == 1 {
    return "Yesterday"
  }
  // Tomorrow
  if day_diff == -1 {
    return "Tomorrow"
  }
  // Within past 7 days: "Last {weekday}"
  if day_diff >= 2 && day_diff <= 7 {
    return "Last " + weekday_name(target.weekday)
  }
  // Within next 7 days: "This {weekday}"
  if day_diff >= -7 && day_diff <= -2 {
    return "This " + weekday_name(target.weekday)
  }
  // Same year: "Month day"
  if target.year == ref_date.year {
    return month_name(target.month) + " " + target.day.to_string()
  }
  // Different year: "Month day, year"
  month_name(target.month) +
  " " +
  target.day.to_string() +
  ", " +
  target.year.to_string()
}

///|
/// Formats a start and end timestamp as a smart date range
///
/// Examples:
/// - Same day: "March 5, 2024"
/// - Same month: "March 5–7, 2024"
/// - Same year: "March 5 – April 7, 2024"
/// - Cross-year: "December 28, 2024 – January 3, 2025"
///
/// Note: If start > end, they are silently swapped
pub fn date_range(start : Int64, end : Int64) -> String {
  // Swap if needed
  let (start, end) = if start > end { (end, start) } else { (start, end) }
  let start_date = timestamp_to_date(start)
  let end_date = timestamp_to_date(end)
  // Same day
  if start_date.year == end_date.year &&
    start_date.month == end_date.month &&
    start_date.day == end_date.day {
    return month_name(start_date.month) +
      " " +
      start_date.day.to_string() +
      ", " +
      start_date.year.to_string()
  }
  // Same month and year: "March 5–7, 2024"
  if start_date.year == end_date.year && start_date.month == end_date.month {
    return month_name(start_date.month) +
      " " +
      start_date.day.to_string() +
      "–" +
      end_date.day.to_string() +
      ", " +
      start_date.year.to_string()
  }
  // Same year: "March 5 – April 7, 2024"
  if start_date.year == end_date.year {
    return month_name(start_date.month) +
      " " +
      start_date.day.to_string() +
      " – " +
      month_name(end_date.month) +
      " " +
      end_date.day.to_string() +
      ", " +
      start_date.year.to_string()
  }
  // Cross-year: "December 28, 2024 – January 3, 2025"
  month_name(start_date.month) +
  " " +
  start_date.day.to_string() +
  ", " +
  start_date.year.to_string() +
  " – " +
  month_name(end_date.month) +
  " " +
  end_date.day.to_string() +
  ", " +
  end_date.year.to_string()
}
