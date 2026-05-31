# YouTube Batch Status

## Latest useful output
- `finish_attraction_youtube_rows_102_151_thai.xlsx`
- This is the latest file with newly found YouTube URLs.
- Total rows with YouTube: 150 rows
- Newly filled today after the previous 100 rows: Excel rows 102-151, 50 rows

## Attempt to continue to row 1000
- Requested target: Excel row 1000
- The run attempted batches up to rows 952-1000.
- YouTube API returned HTTP 403 after row 151, so no useful new YouTube URLs were added after row 151.
- Keep the files after row 151 only as logs/copies, not as useful media output.

## Recommended next run
- Continue from Excel row 152 when the YouTube quota resets.
- Use `finish_attraction_youtube_rows_102_151_thai.xlsx` as the input file.
- Run in batches of 50 rows with `--youtube-query-mode thai-only`.

## Files
- Run log: `youtube_to_1000_run.log`
- Latest useful Excel: `finish_attraction_youtube_rows_102_151_thai.xlsx`
- Last attempted Excel: `finish_attraction_youtube_rows_952_1000_thai.xlsx`
