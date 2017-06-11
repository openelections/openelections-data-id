# openelections-data-id
Pre-processed results for Idaho elections

Idaho [makes available for download](http://www.sos.idaho.gov/ELECT/results/index.html) Excel files with both county and precinct-level results. We are interested in the files marked `Statewide`, `Presidential` and `Legislature` at both the county and precinct levels for primary and general elections dating back to 2000 (although we'd happily accept earlier stuff, too).

Files should be in the following format: `yyyymmdd__id__{election_type}__{geography}.csv`, where `election_type` is either `primary` or `general` and `geography` is either `county` or `precinct`. In the case of presidential primaries where other races are not on the ballot, the `election_type` would be `primary__president`.

The CSV files should have the following headers:

`county`, `precinct`, `office`, `district`, `party`, `candidate`, `votes`

For county-level files you can omit the `precinct` column.

To work on a specific year or years, create an Issue and list which elections you'll be working on. If you have questions, create an Issue or email us at openelections@gmail.com.
