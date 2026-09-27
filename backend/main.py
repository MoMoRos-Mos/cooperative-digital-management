from tracemalloc import Statistic
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import RedirectResponse
from fastapi.middleware.cors import CORSMiddleware

from backend.routers import members
from backend.routers import dashboard

from backend.routers import auth

app = FastAPI(title="Cooperative Digital Management API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://127.0.0.1:5500", "http://localhost:5500"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", include_in_schema=False)
def root():
    return RedirectResponse(url="/app/")


app.include_router(members.router)
app.include_router(dashboard.router)
app.include_router(auth.router)

app.mount("/app", StaticFiles(directory="frontend", html=True), name="frontend")
