import json
import re
from pathlib import Path
from urllib.parse import parse_qs, urlparse


def youtube_video_id(url: str) -> str:
    parsed = urlparse(url)
    if parsed.netloc.endswith("youtu.be"):
        return parsed.path.strip("/")
    if "youtube.com" in parsed.netloc:
        query_id = parse_qs(parsed.query).get("v", [""])[0]
        if query_id:
            return query_id
        match = re.search(r"/(?:embed|shorts)/([^/?#]+)", parsed.path)
        if match:
            return match.group(1)
    return ""


def thumbnail_urls(video_id: str) -> list[str]:
    return [
        f"https://img.youtube.com/vi/{video_id}/maxresdefault.jpg",
        f"https://img.youtube.com/vi/{video_id}/hqdefault.jpg",
    ]


def main() -> None:
    json_path = Path("dataset/attractions.json")
    data = json.loads(json_path.read_text(encoding="utf-8"))

    updated = 0
    for item in data:
        if item.get("images"):
            continue

        youtube_urls = item.get("youtubeUrls") or []
        images: list[str] = []
        for youtube_url in youtube_urls[:2]:
            video_id = youtube_video_id(youtube_url)
            if video_id:
                images.extend(thumbnail_urls(video_id))

        if images:
            item["images"] = images[:4]
            updated += 1

    json_path.write_text(
        json.dumps(data, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Updated images from YouTube thumbnails: {updated}")


if __name__ == "__main__":
    main()
