package service

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	_ "embed"
	"errors"
	"fmt"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"log"
	"time"
)

//go:embed rds-combined-ca-bundle.pem
var caFile []byte

type User struct {
	User     *string `json:"user"`
	Email    *string `json:"email"`
	Password *string `json:"password"`
}

const (

	// Timeout operations after N seconds
	connectTimeout  = 15
	queryTimeout    = 40
	username        = "someusername"
	password        = "somepassword123"
	clusterEndpoint = "my-docdb-cluster.cluster-cwyucqbpng3v.eu-west-1.docdb.amazonaws.com"
	// Which instances to read from
	readPreference           = "secondaryPreferred"
	connectionStringTemplate = "mongodb://%s:%s@%s/sample-database?tls=true&replicaSet=rs0&readpreference=%s"
)

func populateDb(collection *mongo.Collection) {
	ctx, cancel := context.WithTimeout(context.Background(), queryTimeout*time.Second)
	defer cancel()
	res, err := collection.InsertOne(ctx, bson.M{"user": "user123", "email": "user123@gmail.com", "password": "somepassword"})
	if err != nil {
		log.Fatalf("Failed to insert document: %v", err)
	}

	id := res.InsertedID
	log.Printf("Inserted document ID: %s", id)
}

func findByEmail(collection *mongo.Collection, email string) (err error) {
	ctx, cancel := context.WithTimeout(context.Background(), queryTimeout*time.Second)
	defer cancel()
	filter := bson.D{{"email", email}}
	var result User
	err = collection.FindOne(ctx, filter).Decode(&result)

	if err != nil {
		log.Fatalf("Failed to run find query: %v", err)
	}

	if err != nil {
		if err == mongo.ErrNoDocuments {
			// This error means your query did not match any documents.
			return err
		}
	}
	return nil
}
func ConnectDbAndFindUser(email string) (err error) {

	connectionURI := fmt.Sprintf(connectionStringTemplate, username, password, clusterEndpoint, readPreference)
	tlsConfig, err := getCustomTLSConfig(caFile)
	if err != nil {
		log.Fatalf("Failed getting TLS configuration: %v", err)
	}
	client, err := mongo.NewClient(options.Client().ApplyURI(connectionURI).SetTLSConfig(tlsConfig))
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}

	ctx, cancel := context.WithTimeout(context.Background(), connectTimeout*time.Second)
	defer cancel()

	err = client.Connect(ctx)
	if err != nil {
		log.Fatalf("Failed to connect to cluster: %v", err)
	}

	// Force a connection to verify our connection string
	err = client.Ping(ctx, nil)
	if err != nil {
		log.Fatalf("Failed to ping cluster: %v", err)
	}

	fmt.Println("Connected to DocumentDB!")

	collection := client.Database("users-database").Collection("users-collection")

	populateDb(collection)
	err = findByEmail(collection, email)

	return err
}

func getCustomTLSConfig(caFile []byte) (*tls.Config, error) {
	tlsConfig := new(tls.Config)

	tlsConfig.RootCAs = x509.NewCertPool()
	ok := tlsConfig.RootCAs.AppendCertsFromPEM(caFile)

	if !ok {
		return tlsConfig, errors.New("Failed parsing pem file")
	}

	return tlsConfig, nil
}
