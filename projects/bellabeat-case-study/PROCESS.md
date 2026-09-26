# Process & Cleaning Log

A step-by-step record of the data preparation, cleaning, and analysis decisions made for the Bellabeat sleep & activity analysis. Kept here in full so the reasoning behind the final findings is visible, not just the results.

## Tools

Google Sheets — pivot tables, INDEX/MATCH, IFS segmentation, CORREL(). Chosen for fast iteration and full formula transparency.

## Data

FitBit Fitness Tracker Data (Kaggle, CC0 Public Domain). Files used: `dailyActivity_merged`, `sleepDay_merged`.

## Changelog

1. Imported `dailyActivity_merged` and `sleepDay_merged` as separate sheets.
2. Built a composite `MatchKey` (`Id + "_" + date`, via `TEXT(date,"YYYY-MM-DD")`) in both sheets, since a simple Id-only match would incorrectly pair a random day's steps with a random day's sleep for a user with multiple records.
3. In `sleepDay_merged`, added a `Next_Day` column (`SleepDay + 1`) to test whether last night's sleep relates to the *following* day's activity.
4. Used `INDEX`/`MATCH` — not `VLOOKUP` — to pull next-day `TotalSteps` into `sleepDay_merged`, since the target column sat to the left of the `MatchKey` column in `dailyActivity_merged`, a case `VLOOKUP` can't handle.
5. Wrapped the `INDEX`/`MATCH` formula in `IFERROR()` to convert `#N/A` results (users with no logged activity on the matched next day) into blanks rather than raw errors, then filtered these out of the analysis view without deleting the underlying rows.
6. Built a pivot table of each user's average daily `TotalSteps`, sorted ascending.
7. Segmented each user into an activity category using CDC-style step thresholds — Sedentary (<5,000), Low Active (5,000–7,499), Somewhat Active (7,500–9,999), Active (10,000+) — via an `IFS()` formula.
8. Built a second pivot table of each user's average `TotalMinutesAsleep`, then pulled it into the segmented table via `INDEX`/`MATCH`.
9. Built a final pivot table averaging sleep by segment. **Caught and corrected an error** where the pivot defaulted to `SUM` instead of `AVERAGE`, which would have made segments with more users appear to have artificially higher "total" sleep — corrected before drawing any conclusions.
10. Identified a `#DIV/0!` error from a blank/unlabeled segment row, flagged for cleanup in the working sheet (not present in the final reported figures).
