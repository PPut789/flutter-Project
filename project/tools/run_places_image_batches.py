import argparse
import json
import subprocess
import sys
from pathlib import Path


PYTHON = Path(r"C:\Users\poomp\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe")
DATASET = Path(
    r"C:\Users\poomp\OneDrive - Rajamangala University of Technology Thanyaburi"
    r"\Project\Chapter 1 2 3\Dataset\#5 finish_attraction.xlsx"
)
DATASET_DIR = DATASET.parent
JSON_PATH = Path(r"C:\flutter\flutter-Project\project\dataset\attractions.json")


def run(command: list[str], log_file) -> None:
    printable = " ".join(command)
    log_file.write(f"\n\n>>> {printable}\n")
    log_file.flush()

    process = subprocess.Popen(
        command,
        cwd=Path(r"C:\flutter\flutter-Project\project"),
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
    )
    assert process.stdout is not None
    for line in process.stdout:
        print(line, end="", flush=True)
        log_file.write(line)
        log_file.flush()

    exit_code = process.wait()
    if exit_code != 0:
        raise SystemExit(f"Command failed with exit code {exit_code}: {printable}")


def count_images() -> dict:
    data = json.loads(JSON_PATH.read_text(encoding="utf-8"))
    counts: dict[int, int] = {}
    total = 0
    for item in data:
        image_count = len(item.get("images") or [])
        if image_count:
            total += 1
            counts[image_count] = counts.get(image_count, 0) + 1
    return {
        "with_images": total,
        "counts": dict(sorted(counts.items())),
    }


def main() -> None:
    parser = argparse.ArgumentParser(description="Run Google Places image enrichment in batches.")
    parser.add_argument("--start-row", type=int, required=True)
    parser.add_argument("--end-row", type=int, required=True)
    parser.add_argument("--batch-size", type=int, default=50)
    parser.add_argument("--max-images", type=int, default=8)
    parser.add_argument("--sleep", type=float, default=0.2)
    parser.add_argument("--log", default="tools/places_batch_run.log")
    args = parser.parse_args()

    log_path = Path(args.log)
    log_path.parent.mkdir(parents=True, exist_ok=True)

    with log_path.open("a", encoding="utf-8") as log_file:
        log_file.write(
            f"\n=== Places image batch run start rows {args.start_row}-{args.end_row} ===\n"
        )
        log_file.flush()

        current = args.start_row
        while current <= args.end_row:
            batch_end = min(current + args.batch_size - 1, args.end_row)
            limit = batch_end - current + 1
            output = DATASET_DIR / f"#5 finish_attraction_places_images_batch_{current}_{batch_end}.xlsx"

            run(
                [
                    str(PYTHON),
                    "tools/enrich_attraction_places_images.py",
                    "--input",
                    str(DATASET),
                    "--output",
                    str(output),
                    "--start-row",
                    str(current),
                    "--limit",
                    str(limit),
                    "--overwrite",
                    "--min-images",
                    "2",
                    "--max-images",
                    str(args.max_images),
                    "--sleep",
                    str(args.sleep),
                ],
                log_file,
            )

            run(
                [
                    str(PYTHON),
                    "tools/merge_excel_media_to_json.py",
                    "--excel",
                    str(output),
                    "--start-row",
                    str(current),
                    "--end-row",
                    str(batch_end),
                    "--images",
                ],
                log_file,
            )

            summary = count_images()
            summary_text = json.dumps(summary, ensure_ascii=False)
            print(f"Summary after row {batch_end}: {summary_text}", flush=True)
            log_file.write(f"Summary after row {batch_end}: {summary_text}\n")
            log_file.flush()

            current = batch_end + 1

        final_summary = count_images()
        final_text = json.dumps(final_summary, ensure_ascii=False, indent=2)
        print(final_text, flush=True)
        log_file.write(f"\nFinal summary:\n{final_text}\n")
        log_file.write("=== Places image batch run complete ===\n")


if __name__ == "__main__":
    main()
