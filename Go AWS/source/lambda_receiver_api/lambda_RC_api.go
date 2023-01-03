package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/dgrijalva/jwt-go"
	"time"
)

type PostInput struct {
	User  *string `json:"User"`
	Email *string `json:"Email"`
	Data  *string `json:"Data"`
}
type JWTClaim struct {
	Username string `json:"username"`
	Email    string `json:"email"`
	jwt.StandardClaims
}

var jwtKey = []byte("supersecretkey")

func GenerateJWT(email string, username string) (tokenString string, err error) {
	expirationTime := time.Now().Add(1 * time.Hour)
	claims := &JWTClaim{
		Email:    email,
		Username: username,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err = token.SignedString(jwtKey)
	return
}
func ValidateToken(signedToken string) (err error) {
	token, err := jwt.ParseWithClaims(
		signedToken,
		&JWTClaim{},
		func(token *jwt.Token) (interface{}, error) {
			return []byte(jwtKey), nil
		},
	)
	if err != nil {
		return
	}
	claims, ok := token.Claims.(*JWTClaim)
	if !ok {
		err = errors.New("couldn't parse claims")
		return
	}
	if claims.ExpiresAt < time.Now().Local().Unix() {
		err = errors.New("token expired")
		return
	}
	return
}

func lambdaMain(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var postInput PostInput
	err := json.Unmarshal([]byte(request.Body), &postInput)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}
	fmt.Printf(*postInput.Data)
	token, _ := GenerateJWT(*postInput.Email, *postInput.User)
	err = ValidateToken(token)
	return events.APIGatewayProxyResponse{
		Body:       token,
		StatusCode: 200,
	}, err
}

func main() {
	lambda.Start(lambdaMain)
}
