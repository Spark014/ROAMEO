import glob
import os
from typing import List

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
import firebase_admin
from firebase_admin import auth, credentials, firestore

from Sight_info import Sight

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def _load_credentials():
    cred_path = os.environ.get("FIREBASE_CREDENTIALS_PATH")
    if not cred_path:
        candidates = glob.glob(os.path.join(BASE_DIR, "private_key", "*.json"))
        if not candidates:
            raise RuntimeError(
                "Firebase credentials not found. Set FIREBASE_CREDENTIALS_PATH "
                "or place the service account JSON in backend/private_key/."
            )
        cred_path = candidates[0]
    return credentials.Certificate(cred_path)


firebase_admin.initialize_app(_load_credentials())
db = firestore.client()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()


def verify_firebase_token(
    creds: HTTPAuthorizationCredentials = Depends(security),
):
    try:
        return auth.verify_id_token(creds.credentials)
    except Exception as e:
        raise HTTPException(
            status_code=401, detail=f"Invalid or expired token: {e}"
        )


@app.post("/sights/")
async def add_sights(sights: List[Sight]):
    sight_dicts = [sight.dict() for sight in sights]
    doc_ref = db.collection("sights").document()
    doc_ref.set({"sights": sight_dicts})
    return {"message": "Sightseeing mode added successfully", "id": doc_ref.id}


@app.get("/sights/")
async def get_sights():
    return_sights = []
    docs = db.collection("sights").stream()
    for doc in docs:
        sight_data = doc.to_dict().get("sights", [])
        return_sights.append({"id": doc.id, "sights": sight_data})
    return {"sights": return_sights}


@app.get("/sights/{docId}")
async def get_sight_by_id(docId: str):
    doc = db.collection("sights").document(docId).get()
    if doc.exists:
        return {"id": doc.id, "sights": doc.to_dict().get("sights", [])}
    raise HTTPException(status_code=404, detail="Sight not found")


@app.get("/user")
async def get_user(token=Depends(verify_firebase_token)):
    uid = token["uid"]
    user_doc = db.collection("users").document(uid).get()
    if not user_doc.exists:
        raise HTTPException(status_code=404, detail="User not found")
    return {"user": user_doc.to_dict()}


@app.get("/search")
async def search_sights(query: str = Query(...)):
    matching_sights = []
    docs = db.collection("sights").stream()
    for doc in docs:
        sight_data = doc.to_dict().get("sights", [])
        filtered_sights = [
            s
            for s in sight_data
            if query.lower() in s.get("modeName", "").lower()
        ]
        if filtered_sights:
            matching_sights.append({"id": doc.id, "sights": filtered_sights})
    if not matching_sights:
        raise HTTPException(status_code=404, detail="No matching sights found")
    return {"sights": matching_sights}
