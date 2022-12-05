import sqlalchemy as sql
from database import Base

"""
Database models
"""


class User(Base):
    __tablename__: str = "users"
    id = sql.Column(sql.Integer, primary_key=True, index=True)
    email = sql.Column(sql.String, unique=True)
    password = sql.Column(sql.String)


class Game(Base):
    __tablename__: str = "game"
    id = sql.Column(sql.Integer, primary_key=True, index=True)
    players_id = sql.Column(sql.Integer, unique=True)
    board = sql.Column(sql.String)
