import os
import datetime

import bcrypt
import jwt
from fastapi import FastAPI, HTTPException, Query, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from firebase_admin import credentials, firestore, initialize_app
from typing import List

from Sight_info import Sight
from user_model import User
from login_model import LoginRequest

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    pass

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
cred_path = os.path.join(BASE_DIR, 'private_key', 'roameo-f3ab0-firebase-adminsdk-ss40k-4cb207715c.json')

cred = credentials.Certificate(cred_path)
initialize_app(cred)

db = firestore.client()

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ALLOWED_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

JWT_SECRET = os.getenv("JWT_SECRET")
if not JWT_SECRET:
    raise RuntimeError(
        "JWT_SECRET environment variable is required. "
        "Set it in your shell, .env file, or app.yaml env_variables."
    )

#temporary storage for sights
sights_db = []

#add a sight to the db
@app.post("/sights/")
async def add_sights(sights:List[Sight]): #type: ignore

    sight_dicts = [sight.dict() for sight in sights]

    # Save the whole array as one record in Firestore
    doc_ref = db.collection("sights").document()  #Firestore will auto-generate the document ID
    doc_ref.set({"sights": sight_dicts})  

    


    # Add to the local array
    sights_db.append(sight_dicts)
    print("Current sights_db:", sights_db)
    # Get the generated document ID
    doc_id = doc_ref.id
    print("Document ID:", doc_id)
    return {"message": "Sightseeing mode added successfully"}

    


#get all the sights from the db
@app.get("/sights/")
async def get_sights():

    print("Recieved sights")

    return_sights = []
    docs = db.collection("sights").stream()

    for doc in docs:

        #Include document ID and the data
        sight_data = doc.to_dict().get("sights", [])

        return_sights.append({
            #model the response
            "id": doc.id,  
            "sights": sight_data
        })

    return {"sights": return_sights}


#get selected sight by index
@app.get("/sights/{docId}")
async def get_sight_by_id(docId: str):
    # Fetch the specific document from Firestore using the docId
    doc = db.collection("sights").document(docId).get()

    if doc.exists:
        sight_data = doc.to_dict().get("sights", [])
        #Print the received sight data
        print("Received sight data:", sight_data)
        return {"id": doc.id, "sights": sight_data}
    else:
        raise HTTPException(status_code=404, detail="Sight not found")  


def hash_password(password: str) -> str:
    salt = bcrypt.gensalt()
    hashed_password = bcrypt.hashpw(password.encode('utf-8'), salt)
    return hashed_password.decode('utf-8')

def verify_password(password: str, hashed_password: str) -> bool:
    return bcrypt.checkpw(password.encode('utf-8'), hashed_password.encode('utf-8'))

def create_jwt_token(email: str):
    expiration = datetime.datetime.utcnow() + datetime.timedelta(hours=1)
    payload = {"sub": email, "exp": expiration}
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")

def verify_jwt_token(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        payload = jwt.decode(credentials.credentials, JWT_SECRET, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

# Signup endpoint
@app.post("/signup")
async def signup(user: User):
    try:
        hashed_password = hash_password(user.password)
        user_ref = db.collection("users").document()
        user_ref.set({
            "username": user.username,
            "email": user.email,
            "dob": user.dob,
            "password": hashed_password
        })
        # Generate JWT token after successful signup
        token = create_jwt_token(user.email)
        return {"message": "User registered successfully", "token": token}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/login")
async def login(user: LoginRequest):
    try:
        user_ref = db.collection("users").where("email", "==", user.email).stream()
        user_doc = next(user_ref, None)
        if not user_doc:
            raise HTTPException(status_code=400, detail="Invalid email or password")
        user_data = user_doc.to_dict()
        if not verify_password(user.password, user_data["password"]):
            raise HTTPException(status_code=400, detail="Invalid email or password")

        # Checking if the token exists and is valid
        if "token" in user_data:
            try:
                jwt.decode(user_data["token"], JWT_SECRET, algorithms=["HS256"])
                # If the token is valid, reuse it
                return {"message": "Login successful", "token": user_data["token"]}
            except jwt.ExpiredSignatureError:
                # If the token has expired, return 401
                raise HTTPException(status_code=401, detail="Token expired")
            except jwt.InvalidTokenError:
                # If the token is invalid, return 401
                raise HTTPException(status_code=401, detail="Invalid token")

        # Creating a new token
        token = create_jwt_token(user.email)
        user_doc.reference.update({"token": token})
        return {"message": "Login successful", "token": token}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# User endpoint
@app.get("/user")
async def get_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    try:
        # Verify the JWT token
        payload = verify_jwt_token(credentials)
        # Extract the email from the token
        user_email = payload.get("sub")

        # Fetch user data from Firestore
        user_ref = db.collection("users").where("email", "==", user_email).stream()
        user_doc = next(user_ref, None)

        if not user_doc:
            raise HTTPException(status_code=404, detail="User not found")

        user_data = user_doc.to_dict()
        return {"user": user_data}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# Search Sightseeing modes by ModeName
@app.get("/search")
async def search_sights(query: str = Query ):
  
    print(f"Searching for sightseeing modes with query: {query}")
    
    matching_sights = []
    docs = db.collection("sights").stream()

    for doc in docs:
        sight_data = doc.to_dict().get("sights", [])

        # Check each sight's modeName
        filtered_sights = [sight for sight in sight_data if query.lower() in sight.get("modeName", "").lower()]

        if filtered_sights:
            matching_sights.append({
                "id": doc.id,
                "sights": filtered_sights
            })

    if not matching_sights:
        raise HTTPException(status_code=404, detail="No matching sights found")

    return {"sights": matching_sights}