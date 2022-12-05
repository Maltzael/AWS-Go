from pydantic import BaseModel
from typing import Optional

"""
Schemas for models used in routers.
"""


class UserBase(BaseModel):
    email: str


class UserCreate(UserBase):
    password: str

    class Config:
        orm_mode = True


class User(UserBase):
    id: int
    is_active: bool

    class Config:
        orm_mode = True


class ChangeUser(UserBase):
    email: Optional[str]

    class Config:
        orm_mode = True


class ShowUser(BaseModel):
    email: str

    class Config:
        orm_mode = True


class Login(BaseModel):
    email: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    email: str | None = None


class GameBase(BaseModel):
    board: Optional[str] = "nnnnnnnnn"

    class Config:
        orm_mode = True


class CreateBoard(GameBase):
    players_id: int

    class Config:
        orm_mode = True


class Game(GameBase):
    id: int

    class Config:
        orm_mode = True


class ShowBoard(BaseModel):
    board: str

    class Config:
        orm_mode = True


class ChangeBoard(GameBase):
    board: Optional[str]

    class Config:
        orm_mode = True
