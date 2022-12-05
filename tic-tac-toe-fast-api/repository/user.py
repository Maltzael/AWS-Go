import schemas
import models
from sqlalchemy.orm import Session
from auth.hashing import Hash
from fastapi import status, HTTPException
from pydantic import validate_email, EmailError, ValidationError


def create(request: schemas.UserCreate, db: Session):
    try:
        validate_email(request.email)
    except EmailError or ValidationError:
        return status.HTTP_406_NOT_ACCEPTABLE

    new_user = models.User(email=request.email, password=Hash.bcrypt(request.password))
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user


def get(id: int, db: Session):
    user = db.query(models.User).filter(models.User.id == id).first()
    if not user:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User with the id {id} is not available")
    return user


def delete(id: int, db: Session):
    user = db.query(models.User).filter(models.User.id == id)
    if not user.first():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User with the id {id} is not available")
    user.delete(synchronize_session=False)
    db.commit()
    return "Done"


def update(id: int, request: schemas.ChangeUser, db: Session):
    user = db.query(models.User).filter(models.User.id == id)
    if not user.first():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=f"User with the id {id} is not available")
    user.update(request.dict())
    db.commit()
    return "Updated"
