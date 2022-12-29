package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

//type Postinput struct {
//	Fruit string `json:"fruit"`
//	Size  string `json:"size"`
//	Color string `json:"color"`
//	Key1  string `json:"key1"`
//}

func handleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	fmt.Printf("event.Body %v\n", request.Body)
	body := fmt.Sprintf("Hello from labmda! Body: %v\n", request.Body)
	return events.APIGatewayProxyResponse{
		Body:       body,
		StatusCode: 200,
	}, nil
}

func main() {
	lambda.Start(handleRequest)

}
