package main

import (
	"Go_AWS/service"
	"context"
	"encoding/json"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"log"
)

//type PostInputWithToken struct {
//	Token *string `json:"token"`
//	Data  *string `json:"data"`
//}

func lambdaMain(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var postInput service.ResponseBody
	err := json.Unmarshal([]byte(request.Body), &postInput)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}
	_, err = service.ValidateToken(postInput.Token)
	if err != nil {
		return events.APIGatewayProxyResponse{}, err
	}
	fmt.Printf(*postInput.Data, postInput.ExpirationTime)
	body, _ := json.Marshal(service.ResponseBody{Token: postInput.Token, ExpirationTime: postInput.ExpirationTime, Data: postInput.Data})
	log.Print(body)
	return events.APIGatewayProxyResponse{
		Body:       string(body),
		StatusCode: 200,
	}, err
}

func main() {
	lambda.Start(lambdaMain)
}
