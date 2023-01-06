package main

import (
	"Go_AWS/service"
	"context"
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/dgrijalva/jwt-go"
	"log"
	"time"
)

var expirationTimeDuration = time.Hour * 1

type PostInput struct {
	User  *string `json:"user"`
	Email *string `json:"email"`
	Data  *string `json:"data"`
}

func GenerateJWT(email string, username string) (tokenString string, expTime time.Time, err error) {
	expirationTime := time.Now().Add(expirationTimeDuration)
	claims := &service.JWTClaim{
		Email:    email,
		Username: username,
		StandardClaims: jwt.StandardClaims{
			ExpiresAt: expirationTime.Unix(),
		},
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err = token.SignedString(service.JwtKey)
	log.Print(tokenString)
	return tokenString, expirationTime, err
}

func lambdaMain(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var postInput PostInput
	err := json.Unmarshal([]byte(request.Body), &postInput)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}
	//log.Printf(*postInput.User, *postInput.Email, postInput.Data)
	token, expTime, err := GenerateJWT(*postInput.Email, *postInput.User)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}
	body, err := json.Marshal(service.ResponseBody{Token: token, ExpirationTime: expTime, Data: postInput.Data})
	log.Print(token, expTime, postInput.Data)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}
	return events.APIGatewayProxyResponse{
		Body:       string(body),
		StatusCode: 200,
	}, err
}

func main() {
	lambda.Start(lambdaMain)
}
