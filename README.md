# whenword-mbt

A relative time formatting library for MoonBit.

## Background

This is a MoonBit implementation of [whenwords](https://github.com/dbreunig/whenwords), an experimental "software library with no code" by Drew Breunig.

The original whenwords project contains only specifications (SPEC.md) and tests (tests.yaml) - no implementation code. The idea is that AI coding agents can generate working implementations from specs alone.

**Reference article:** [A Software Library with No Code](https://www.dbreunig.com/2026/01/08/a-software-library-with-no-code.html)

This repository demonstrates that the whenwords specification can be successfully implemented in MoonBit by an AI coding agent.

## Installation

```bash
moon add mizchi/whenword
```

## Usage

```moonbit
// Relative time formatting
@whenword.timeago(1705190400L, reference=1705276800L)  // "1 day ago"
@whenword.timeago(1705280400L, reference=1705276800L)  // "in 1 hour"

// Duration formatting
@whenword.duration(9000L)  // "2 hours, 30 minutes"
@whenword.duration(9000L, options={ compact: true, max_units: 2 })  // "2h 30m"

// Duration parsing
@whenword.parse_duration("2h 30m")  // 9000
@whenword.parse_duration("2:30:00")  // 9000
@whenword.parse_duration("2.5 hours")  // 9000

// Human-readable dates
@whenword.human_date(1705190400L, reference=1705276800L)  // "Yesterday"
@whenword.human_date(1705363200L, reference=1705276800L)  // "Tomorrow"
@whenword.human_date(1704844800L, reference=1705276800L)  // "Last Wednesday"

// Date ranges
@whenword.date_range(1705276800L, 1705449600L)  // "January 15-17, 2024"
```

## API

### `timeago(timestamp: Int64, reference~: Int64) -> String`

Converts a timestamp to a relative time string like "3 hours ago" or "in 2 days".

### `duration(seconds: Int64, options~: DurationOptions) -> String`

Formats a number of seconds as a human-readable duration.

**Options:**
- `compact: Bool` - Use compact format like "2h 30m" (default: false)
- `max_units: Int` - Maximum number of units to display (default: 2)

### `parse_duration(input: String) -> Int64 raise ParseDurationError`

Parses a duration string into seconds. Supports compact ("2h30m"), verbose ("2 hours 30 minutes"), decimal ("2.5 hours"), and colon ("2:30:00") formats.

### `human_date(timestamp: Int64, reference~: Int64) -> String`

Returns a contextual date string like "Today", "Yesterday", "Last Tuesday", or "March 5".

### `date_range(start: Int64, end: Int64) -> String`

Formats a start and end timestamp as a smart date range.

## Testing

```bash
moon test
```

69 tests covering all five functions.

## License

MIT

## Credits

- Original [whenwords specification](https://github.com/dbreunig/whenwords) by Drew Breunig
