build-receiver:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o  bin/lambda_receiver source/lambda_receiver/lambda_RC.go
build-sender:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o  bin/lambda_sender source/lambda_sender/lambda_ST.go
build-receiver-api:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o  bin/lambda_receiver_api source/lambda_receiver_api/lambda_RC_api.go
terraform-on:
	terraform plan
	terraform apply -auto-approve
terraform-off:
	terraform destroy -auto-approve
all:	build-all
	echo "all"
build-all:    build-receiver build-sender build-receiver-api terraform-on
	echo "build all - done"