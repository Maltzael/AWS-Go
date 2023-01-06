build-receiver-from-kinesis:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o  bin/lambda_receiver_from_kinesis source/lambda_receiver_from_kinesis/lambda_receiver_from_kinesis.go
build-receiver-from-s3:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o  bin/lambda_receiver_from_s3 source/lambda_receiver_from_s3/lambda_receiver_from_s3.go
build-receiver-auth:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o  bin/lambda_receiver_auth source/lambda_receiver_auth/lambda_receiver_auth.go
build-receiver-from-api:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o  bin/lambda_receiver_from_api source/lambda_receiver_from_api/lambda_receiver_from_api.go
terraform-on:
	terraform plan
	terraform apply -auto-approve
terraform-off:
	terraform destroy -auto-approve
all:	build-all
	echo "all"
build-all:    build-receiver-from-kinesis build-receiver-from-s3 build-receiver-auth build-receiver-from-api terraform-on
	echo "build all - done"