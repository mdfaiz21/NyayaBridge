

from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from google import genai
from PIL import Image
import io
import time
import firebase_admin
from firebase_admin import credentials, messaging

# ==========================================
# 1. FIREBASE ADMIN SETUP
# ==========================================
try:
    # This must be in your root backend folder
    cred = credentials.Certificate("serviceAccountKey.json")
    firebase_admin.initialize_app(cred)
    print("Firebase Admin Initialized Successfully!")
except Exception as e:
    print("Firebase Admin already initialized or key missing:", e)

# ==========================================
# 2. APP INITIALIZATION
# ==========================================
app = FastAPI(title="NyayaBridge AI Backend")

# 🛡️ CORS Middleware for Flutter/Web Communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ⚠️ GEMINI AI CONFIGURATION
GEMINI_API_KEY = "Gemini key here"
client = genai.Client(api_key=GEMINI_API_KEY)

# ==========================================
# 3. DATA MODELS
# ==========================================
class SOSRequest(BaseModel):
    city: str
    category: str

class ChatRequest(BaseModel):
    text: str

# ==========================================
# 4. API ENDPOINTS
# ==========================================

# --- FEATURE 1: SOS Broadcast System (UPGRADED WITH NATIVE ALARM) ---
@app.post("/api/broadcast-sos")
async def broadcast_sos(request: SOSRequest):
    try:
        # Clean the city name to make it a valid radio topic (e.g., "New Delhi" -> "new_delhi")
        safe_city = request.city.lower().replace(" ", "_").replace("/", "")
        topic = f"sos_{safe_city}"

        message = messaging.Message(
            notification=messaging.Notification(
                title=f"🚨 URGENT: {request.category} SOS",
                body="A citizen in your area requires immediate legal assistance. Open the app now!"
            ),
            # 🚀 THIS IS THE MISSING MAGIC BLOCK!
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    sound="siren", # Tells Android to wake up and play res/raw/siren.mp3
                    channel_id="sos_alerts", # Targets the channel we made in main.dart
                    default_vibrate_timings=True,
                    default_sound=False,
                ),
            ),
            topic=topic,
        )

        # Fire the notification!
        response = messaging.send(message)
        return {"status": "success", "message_id": response}
    except Exception as e:
        print(f"Push Notification Error: {e}")
        return {"status": "failed", "error": str(e)}

# --- FEATURE 2: AI Intake Chat ---
@app.post("/api/chat")
async def chat_with_ai(request: ChatRequest):
    try:
        system_prompt = """
        You are the NyayaBridge AI Legal Assistant. Your job is to listen to the user's issue,
        figure out what category of law it falls under (Property, Family, Business, Criminal),
        and provide a brief, professional, comforting response. Keep answers under 4 sentences.
        """

        response = client.models.generate_content(
            model='gemini-2.5-pro',
            contents=f"{system_prompt}\n\nUser says: {request.text}"
        )

        return {"reply": response.text}
    except Exception as e:
        return {"reply": f"Connection Error: Could not reach the AI brain. Details: {str(e)}"}

# --- FEATURE 3: AI Document Scanner (OCR) ---
@app.post("/api/ocr/analyze")
async def analyze_document(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))

        prompt = """
        You are an expert legal assistant. Read this document and provide exactly this format:
        1. Document Type: (What is this?)
        2. Summary: (A simple, 2-3 sentence explanation for a normal person)
        3. Key Action Items: (What does the user need to do next?)
        4. Urgency: (High/Medium/Low)
        """

        response = client.models.generate_content(
            model='gemini-2.5-pro',
            contents=[prompt, image]
        )

        return {"status": "success", "analysis": response.text}

    except Exception as e:
        print(f"\n========== AI CRASH DETAILS ==========")
        print(f"Error Type: {type(e).__name__}")
        print(f"Error Message: {str(e)}")
        print(f"======================================\n")
        raise HTTPException(status_code=500, detail=str(e))

# --- FEATURE 4: Mock Nearby Lawyers ---
@app.get("/api/sos/nearby")
async def get_nearby_lawyers():
    time.sleep(2)
    lawyers = [
        {"id": 1, "name": "Adv. Ramesh Kumar", "distance": "0.8 km", "specialty": "Criminal Defense", "phone": "+91 9876543210"},
        {"id": 2, "name": "Adv. Priya Sharma", "distance": "1.2 km", "specialty": "Bail & Arrest", "phone": "+91 8765432109"},
        {"id": 3, "name": "Adv. Vikram Singh", "distance": "2.5 km", "specialty": "Civil Rights", "phone": "+91 7654321098"}
    ]
    return {"status": "success", "lawyers": lawyers}

# --- FEATURE 5: Health Check (For Render Deployment) ---
@app.get("/")
@app.head("/")
async def root():
    return {"status": "online", "message": "NyayaBridge AI is active"}

# 🚀 FIX 2: Explicitly handle HEAD requests for UptimeRobot
@app.get("/healthz")
@app.head("/healthz")
async def health_check():
    return {"status": "awake"}

# ==========================================
# 5. SERVER RUNNER
# ==========================================
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

