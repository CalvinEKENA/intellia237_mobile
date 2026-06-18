from __future__ import annotations

import argparse
import io
import json
import logging
import mimetypes
import os
from pathlib import Path
from typing import Any

import firebase_admin
from firebase_admin import credentials, firestore, storage
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload


logger = logging.getLogger("drive-ingestion")
DEFAULT_STATE_PATH = Path(".drive_ingestion_state.json")


def initialize_firebase(project_id: str, bucket_name: str) -> tuple[firestore.Client, Any]:
    if not firebase_admin._apps:
        use_emulator = bool(os.getenv("FIRESTORE_EMULATOR_HOST"))
        if use_emulator:
            firebase_admin.initialize_app(
                options={"projectId": project_id, "storageBucket": bucket_name}
            )
        else:
            firebase_admin.initialize_app(
                credentials.ApplicationDefault(),
                {"projectId": project_id, "storageBucket": bucket_name},
            )
    return firestore.client(), storage.bucket()


def load_state(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {"page_token": None, "processed_ids": []}
    return json.loads(path.read_text(encoding="utf-8"))


def save_state(path: Path, state: dict[str, Any]) -> None:
    path.write_text(json.dumps(state, indent=2), encoding="utf-8")


def build_drive_service():
    return build("drive", "v3", cache_discovery=False)


def list_image_files(drive_service, folder_id: str, page_token: str | None, page_size: int):
    return (
        drive_service.files()
        .list(
            q=(
                f"'{folder_id}' in parents and trashed = false and "
                "(mimeType contains 'image/')"
            ),
            spaces="drive",
            fields="nextPageToken, files(id, name, mimeType, size, md5Checksum, modifiedTime)",
            pageToken=page_token,
            pageSize=page_size,
        )
        .execute()
    )


def download_drive_file(drive_service, file_id: str) -> bytes:
    request = drive_service.files().get_media(fileId=file_id)
    buffer = io.BytesIO()
    downloader = MediaIoBaseDownload(buffer, request)

    done = False
    while not done:
        _, done = downloader.next_chunk()

    return buffer.getvalue()


def upload_to_storage(bucket_handle, course_id: str, file_name: str, content: bytes, content_type: str) -> str:
    safe_name = file_name.replace("\\", "-").replace("/", "-")
    blob_path = f"courses/{course_id}/images/{safe_name}"
    blob = bucket_handle.blob(blob_path)
    blob.upload_from_string(content, content_type=content_type)
    return blob_path


def write_image_metadata(
    db: firestore.Client,
    course_id: str,
    file_entry: dict[str, Any],
    storage_path: str,
) -> None:
    db.collection("courses").document(course_id).collection("images").document(file_entry["id"]).set(
        {
            "fileName": file_entry["name"],
            "storagePath": storage_path,
            "contentType": file_entry.get("mimeType"),
            "sizeBytes": int(file_entry.get("size", 0)) if file_entry.get("size") else None,
            "checksum": file_entry.get("md5Checksum"),
            "caption": None,
            "ocrText": None,
            "source": {
                "provider": "google-drive",
                "driveFileId": file_entry["id"],
                "modifiedTime": file_entry.get("modifiedTime"),
            },
            "ingestedAt": firestore.SERVER_TIMESTAMP,
        },
        merge=True,
    )


def ingest(args: argparse.Namespace) -> None:
    state_path = Path(args.state_file)
    state = load_state(state_path)
    drive_service = build_drive_service()
    db, bucket_handle = initialize_firebase(args.project_id, args.bucket)

    page_token = state.get("page_token")
    processed_ids = set(state.get("processed_ids", []))

    while True:
        listing = list_image_files(drive_service, args.drive_folder_id, page_token, args.page_size)
        files = listing.get("files", [])
        logger.info("Fetched %s file(s) from Drive.", len(files))

        for file_entry in files:
            file_id = file_entry["id"]
            if file_id in processed_ids:
                logger.info("Skipping already processed file %s", file_id)
                continue

            try:
                content = download_drive_file(drive_service, file_id)
                content_type = file_entry.get("mimeType") or mimetypes.guess_type(file_entry["name"])[0] or "application/octet-stream"
                storage_path = upload_to_storage(
                    bucket_handle=bucket_handle,
                    course_id=args.course_id,
                    file_name=file_entry["name"],
                    content=content,
                    content_type=content_type,
                )
                write_image_metadata(db, args.course_id, file_entry, storage_path)
                processed_ids.add(file_id)
                state["processed_ids"] = sorted(processed_ids)
                save_state(state_path, state)
                logger.info("Ingested %s -> %s", file_entry["name"], storage_path)
            except Exception as exc:  # noqa: BLE001
                logger.exception("Failed to ingest Drive file %s: %s", file_entry["name"], exc)
                state["last_error"] = {"fileId": file_id, "message": str(exc)}
                save_state(state_path, state)
                if not args.continue_on_error:
                    raise

        page_token = listing.get("nextPageToken")
        state["page_token"] = page_token
        save_state(state_path, state)

        if not page_token:
            logger.info("Drive ingestion completed.")
            break


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Ingest course images from Google Drive into Firebase Storage.")
    parser.add_argument("--project-id", default=os.getenv("FIREBASE_PROJECT_ID", "edunova-aabd1"))
    parser.add_argument("--bucket", default=os.getenv("FIREBASE_STORAGE_BUCKET", "edunova-aabd1.firebasestorage.app"))
    parser.add_argument("--course-id", required=True)
    parser.add_argument("--drive-folder-id", required=True)
    parser.add_argument("--page-size", type=int, default=50)
    parser.add_argument("--state-file", default=str(DEFAULT_STATE_PATH))
    parser.add_argument("--continue-on-error", action="store_true")
    return parser.parse_args()


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
    ingest(parse_args())
