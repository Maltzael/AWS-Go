from fastapi import FastAPI
import models
from database import engine
from routers import users, games, authentication
from fastapi_versioning import VersionedFastAPI

models.Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Fast API tic tac toe game",
    description="Project prototype, based on Fast API tic-tac-toe game",
    version="v1",
)

app.include_router(users.router)
app.include_router(games.router)
app.include_router(authentication.router)

app = VersionedFastAPI(app, version_format="{major}",
                       prefix_format="/v{major}")
