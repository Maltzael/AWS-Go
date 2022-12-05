from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
import schemas
from database import get_db
from repository import game

from fastapi_versioning import version

router = APIRouter(
    tags=["game"],
    prefix="/game"
)


@router.post("/", response_model=schemas.ShowBoard)
@version(1)
def create_board(request: schemas.CreateBoard, db: Session = Depends(get_db)):
    return game.create(request, db)


@router.get("/{id}", response_model=schemas.ShowBoard)
@version(1)
def get_game_by_id(id: int, db: Session = Depends(get_db)):
    return game.get(id, db)


# current_user: schemas.User = Depends(oauth2.get_current_user)

@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
@version(1)
def delete_game(id: int, db: Session = Depends(get_db)):
    return game.delete(id, db)


@router.put("/", status_code=status.HTTP_202_ACCEPTED)
@version(1)
def create_game(id: int, request: schemas.ChangeBoard, db: Session = Depends(get_db)):
    return game.update(id, request, db)
