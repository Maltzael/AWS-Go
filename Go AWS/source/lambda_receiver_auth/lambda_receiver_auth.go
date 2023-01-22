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

var expirationTimeDuration = time.Hour * 3

type PostInput struct {
	User     *string `json:"user"`
	Email    *string `json:"email"`
	Password *string `json:"password"`
	Data     string  `json:"data"`
}

//ToDO: dopisac baze danych z prawdziwa weryfikacja usera
//Todo: uzyj do tego dokumentDb
//todo: stworzyc z pomoca terrraforma dokumentdb i ma dzialac
//todo: biblioteki mongo do uzywania tego

//todo: google big querry json s3 oraz z api ->lambda wysylal do big querry
//
//todo: narysuj io draw tego projektuz

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
	return tokenString, expirationTime, err
}

func lambdaMain(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var postInput PostInput
	err := json.Unmarshal([]byte(request.Body), &postInput)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}

	//Validation with documentDb data
	err = service.ConnectDbAndFindUser(*postInput.Email)
	if err != nil {
		log.Printf("Error in Connection to DB")
		return events.APIGatewayProxyResponse{}, err
	}

	token, expTime, err := GenerateJWT(*postInput.Email, *postInput.User)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}
	body, err := json.Marshal(service.ResponseBody{Token: token, ExpirationTime: expTime, Data: postInput.Data})
	log.Print("Body in json:", string(body))
	if err != nil {
		message, _ := json.Marshal(service.ResponseError{Error: err})
		return events.APIGatewayProxyResponse{
			Body:       string(message),
			StatusCode: 401,
		}, err
	}
	return events.APIGatewayProxyResponse{
		Body:       string(body),
		StatusCode: 200,
	}, err
}

func main() {
	lambda.Start(lambdaMain)
}
