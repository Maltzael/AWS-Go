package main

import (
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/endpoints"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kinesis"
)

//type MyEvent struct {
//	Name string `json:"name"`
//}

//type PutRecordOutput struct {
//	Name string `json:"name"`
//}
//
//func HandleRequest(ctx context.Context, name MyEvent) (string, error) {
//	return fmt.Sprintf("Hello %s!", name.Name), nil
//}

func main() {
	s := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(endpoints.EuWest1RegionID),
	}))
	kc := kinesis.New(s)
	streamName := aws.String("kinesis_stream")
	data := "cosdowysłania"
	putOutput, err := kc.PutRecord(&kinesis.PutRecordInput{
		Data:         []byte(data),
		StreamName:   streamName,
		PartitionKey: aws.String("key1"),
	})
	if err != nil {
		panic(err)
	}
	fmt.Printf("%v\n", *putOutput)

}
