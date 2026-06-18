from __future__ import annotations

import json
import os
from pathlib import Path

import firebase_admin
from firebase_admin import credentials, firestore


ROOT = Path(__file__).resolve().parents[1]
SAMPLE_PATH = ROOT / "samples" / "firestore" / "course.sample.json"


def initialize_firebase(project_id: str) -> firestore.Client:
    if firebase_admin._apps:
        return firestore.client()

    use_emulator = bool(os.getenv("FIRESTORE_EMULATOR_HOST"))
    if use_emulator:
        firebase_admin.initialize_app(options={"projectId": project_id})
    else:
        firebase_admin.initialize_app(credentials.ApplicationDefault(), {"projectId": project_id})
    return firestore.client()


def main() -> None:
    project_id = os.getenv("FIREBASE_PROJECT_ID", "edunova-aabd1")
    db = initialize_firebase(project_id)

    payload = json.loads(SAMPLE_PATH.read_text(encoding="utf-8"))
    course = payload["course"]
    images = payload["images"]
    course_id = course.pop("id")

    course_ref = db.collection("courses").document(course_id)
    course_ref.set(course)

    for image in images:
        image_id = image.pop("id")
        course_ref.collection("images").document(image_id).set(image)

    print(f"Seeded sample course: {course_id}")


if __name__ == "__main__":
    main()
