package main

import (
	"context"
	"fmt"
	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/endpoints"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/kinesis"
	"github.com/aws/aws-sdk-go/service/s3"
	"io/ioutil"
	"log"
)

func GetFromS3(bucketName string, fileName string) string {
	sess := SessionMaker()
	conS3 := s3.New(sess)
	input := &s3.GetObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(fileName),
	}
	result, err := conS3.GetObject(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case s3.ErrCodeNoSuchKey:
				fmt.Println(s3.ErrCodeNoSuchKey, aerr.Error())
			case s3.ErrCodeInvalidObjectState:
				fmt.Println(s3.ErrCodeInvalidObjectState, aerr.Error())
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			fmt.Println(err.Error())
		}
	}
	defer result.Body.Close()
	body, err := ioutil.ReadAll(result.Body)
	if err != nil {
		log.Print(err)
	}

	return string(body)
}
func GetEventData(ctx context.Context, s3Event events.S3Event) (bucketName string, fileName string) {
	for _, record := range s3Event.Records {
		s3 := record.S3
		return s3.Bucket.Name, s3.Object.Key
	}
	return
}

func SessionMaker() *session.Session {
	sess := session.Must(session.NewSession(&aws.Config{
		Region: aws.String(endpoints.EuWest1RegionID),
	}))
	return sess
}

func SendToKinesis(dataToSend string) {
	sess := SessionMaker()
	kin := kinesis.New(sess)
	streamName := aws.String("kinesis_stream")
	data := dataToSend
	_, err := kin.PutRecord(&kinesis.PutRecordInput{
		Data:         []byte(data),
		StreamName:   streamName,
		PartitionKey: aws.String("key1"),
	})
	if err != nil {
		fmt.Printf("%s", err)
	}
}

func DeleteFromS3(bucketName string, fileName string) error {
	sess := SessionMaker()
	conS3 := s3.New(sess)
	input := &s3.DeleteObjectInput{
		Bucket: aws.String(bucketName),
		Key:    aws.String(fileName),
	}
	result, err := conS3.DeleteObject(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			default:
				fmt.Println(aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			fmt.Println(err.Error())
		}
	}

	fmt.Println(result, "\t Delete done!")
	return err
}

func LambdaMain(ctx context.Context, s3Event events.S3Event) error {
	bucketName, fileName := GetEventData(ctx, s3Event)
	data := GetFromS3(bucketName, fileName)
	fmt.Println(data)
	SendToKinesis(data)
	err := DeleteFromS3(bucketName, fileName)
	return err
}

func main() {
	lambda.Start(LambdaMain)
}
