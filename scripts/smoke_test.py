from __future__ import annotations

import json
import os
from pathlib import Path

import firebase_admin
import requests
from firebase_admin import auth, credentials


ROOT = Path(__file__).resolve().parents[1]


def initialize_firebase(project_id: str) -> None:
    if firebase_admin._apps:
        return

    use_emulator = bool(os.getenv("FIRESTORE_EMULATOR_HOST") or os.getenv("FIREBASE_AUTH_EMULATOR_HOST"))
    if use_emulator:
        firebase_admin.initialize_app(options={"projectId": project_id})
    else:
        firebase_admin.initialize_app(credentials.ApplicationDefault(), {"projectId": project_id})


def ensure_test_user(email: str, password: str, uid: str) -> None:
    try:
        auth.get_user(uid)
    except auth.UserNotFoundError:
        auth.create_user(uid=uid, email=email, password=password)


def sign_in_with_auth_emulator(email: str, password: str) -> str:
    emulator_host = os.getenv("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9100")
    response = requests.post(
        f"http://{emulator_host}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key",
        json={
            "email": email,
            "password": password,
            "returnSecureToken": True,
        },
        timeout=10,
    )
    response.raise_for_status()
    return response.json()["idToken"]


def call_callable(function_url: str, id_token: str, data: dict) -> dict:
    response = requests.post(
        function_url,
        headers={
            "Authorization": f"Bearer {id_token}",
            "Content-Type": "application/json",
        },
        json={"data": data},
        timeout=60,
    )
    response.raise_for_status()
    body = response.json()
    if "result" not in body:
        raise RuntimeError(f"Unexpected callable response: {json.dumps(body, indent=2)}")
    return body["result"]


def main() -> None:
    project_id = os.getenv("FIREBASE_PROJECT_ID", "edunova-aabd1")
    region = os.getenv("FUNCTIONS_REGION", "europe-west1")
    functions_base_url = os.getenv("FUNCTIONS_BASE_URL", "http://127.0.0.1:5005")
    course_id = os.getenv("SMOKE_TEST_COURSE_ID", "course_demo_sciences_001")
    email = os.getenv("SMOKE_TEST_EMAIL", "teacher@example.com")
    password = os.getenv("SMOKE_TEST_PASSWORD", "Passw0rd!")
    uid = os.getenv("SMOKE_TEST_UID", "teacher-smoke-test")

    initialize_firebase(project_id)
    ensure_test_user(email=email, password=password, uid=uid)
    id_token = sign_in_with_auth_emulator(email=email, password=password)

    quiz_result = call_callable(
        f"{functions_base_url}/{project_id}/{region}/generateQuiz",
        id_token,
        {
            "courseId": course_id,
            "count": 4,
            "difficulty": "medium",
        },
    )
    summary_result = call_callable(
        f"{functions_base_url}/{project_id}/{region}/generateSummary",
        id_token,
        {
            "courseId": course_id,
            "level": "standard",
        },
    )

    print("Quiz result:")
    print(json.dumps(quiz_result, indent=2, ensure_ascii=False))
    print("\nSummary result:")
    print(json.dumps(summary_result, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
