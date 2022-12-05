from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session
import schemas
from database import get_db
from repository import user
from auth import oauth2
from fastapi_versioning import version

router = APIRouter(
    tags=["users"],
    prefix="/users"
)


@router.post("/", response_model=schemas.ShowUser)
@version(1)
def create_user(request: schemas.UserCreate, db: Session = Depends(get_db)):
    return user.create(request, db)


@version(1)
@router.get("/{id}", response_model=schemas.ShowUser)
def get_user_by_id(id: int, db: Session = Depends(get_db),
                   current_user: schemas.User = Depends(oauth2.get_current_user)):
    return user.get(id, db)


@router.delete("/{id}", status_code=status.HTTP_204_NO_CONTENT)
@version(1)
def delete_user(id: int, db: Session = Depends(get_db),
                current_user: schemas.User = Depends(oauth2.get_current_user)):
    return user.delete(id, db)


@router.put("/", status_code=status.HTTP_202_ACCEPTED)
@version(1)
def create_user(id: int, request: schemas.ChangeUser, db: Session = Depends(get_db),
                current_user: schemas.User = Depends(oauth2.get_current_user)):
    return user.update(id, request, db)
