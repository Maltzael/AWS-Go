package service

import (
	"encoding/json"
	"errors"
	"github.com/aws/aws-lambda-go/events"
	"github.com/dgrijalva/jwt-go"
	"time"
)

type ResponseBody struct {
	Token          string    `json:"token"`
	ExpirationTime time.Time `json:"expirationTime"`
	Data           *string   `json:"data"`
}

type JWTClaim struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	jwt.StandardClaims
}

type ResponseError struct {
	Error error `json:"error"`
}

var JwtKey = []byte("supersecretkey")

func ValidateToken(signedToken string) (events.APIGatewayProxyResponse, error) {
	token, err := jwt.ParseWithClaims(
		signedToken,
		&JWTClaim{},
		func(token *jwt.Token) (interface{}, error) {
			return []byte(JwtKey), nil
		},
	)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}
	claims, ok := token.Claims.(*JWTClaim)
	if !ok {
		err = errors.New("couldn't parse claims")
		message, _ := json.Marshal(ResponseError{Error: err})
		return events.APIGatewayProxyResponse{
			Body:       string(message),
			StatusCode: 406,
		}, err
	}
	if claims.ExpiresAt < time.Now().Local().Unix() {
		err = errors.New("token expired")
		message, _ := json.Marshal(ResponseError{Error: err})
		return events.APIGatewayProxyResponse{
			Body:       string(message),
			StatusCode: 401,
		}, err
	}
	return events.APIGatewayProxyResponse{}, err
}
