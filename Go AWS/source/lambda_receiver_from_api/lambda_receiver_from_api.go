package main

import (
	"Go_AWS/service"
	"context"
	"encoding/json"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"log"
)

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
	body, _ := json.Marshal(service.ResponseBody{Token: postInput.Token, ExpirationTime: postInput.ExpirationTime, Data: postInput.Data})
	log.Print(string(body))
	return events.APIGatewayProxyResponse{
		Body:       string(body),
		StatusCode: 200,
	}, err
}

func main() {
	lambda.Start(lambdaMain)
}
