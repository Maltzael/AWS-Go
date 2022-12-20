build-receiver:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o  bin/lambda_receiver source/lambda_receiver/lambda_RC.go
build-sender:
	GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o  bin/lambda_sender source/lambda_sender/lambda_ST.go
terraform-on:
	terraform plan
	terraform apply -auto-approve
terraform-off:
	terraform destroy -auto-approve
all:	build-all
	echo "all"
build-all:    build-receiver build-sender terraform-on
	echo "build all - done"