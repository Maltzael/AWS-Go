import schemas
import models
from sqlalchemy.orm import Session
from fastapi import status, HTTPException


def create(request: schemas.CreateBoard, db: Session):
    new_game = models.Game(board=request.board, players_id=request.players_id)
    db.add(new_game)
    db.commit()
    db.refresh(new_game)
    return new_game


def get(id: int, db: Session):
    game = db.query(models.Game).filter(models.Game.id == id).first()
    if not game:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Game with the id {id} is not available")
    return game


def delete(id: int, db: Session):
    game = db.query(models.Game).filter(models.Game.id == id)
    if not game.first():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Game with the id {id} is not available")
    game.delete(synchronize_session=False)
    db.commit()
    return "Done"


def update(id: int, request: schemas.ChangeBoard, db: Session):
    game = db.query(models.Game).filter(models.Game.id == id)
    if not game.first():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"Game with the id {id} is not available")
    game.update(request.dict())
    db.commit()
    return "Updated"
