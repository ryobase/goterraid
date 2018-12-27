package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/json-iterator/go"
	"github.com/rs/xid"
	"github.com/ryobase/goterraid/version"
)

var json = jsoniter.ConfigCompatibleWithStandardLibrary
var tableName = "GoTerraIdTable"

// VisitorJSON is response model
type VisitorJSON struct {
	ID         string    `json:"id"`
	VisitorNum int64     `json:"visitor_number"`
	Message    string    `json:"message"`
	Timestamp  time.Time `json:"timestamp"`
}

// PrettyPrint will pretty print variable (struct, map, array, slice).
func PrettyPrint(v interface{}) (err error) {
	if b, err := json.MarshalIndent(v, "", "  "); err == nil {
		fmt.Println(string(b))
		return nil
	}
	return err
}

// generateAndRecord will generate a new UUID and put it a database table before return it.
func generateAndRecord() (item VisitorJSON, err error) {
	guid := xid.New()
	fmt.Printf("Here is your fucking ID: %s\n", guid.String())

	// Initialize the session
	sess, err := session.NewSession(&aws.Config{
		Region: aws.String("us-east-2"),
	})
	if err != nil {
		fmt.Println("Unable to start a DynamoDB session:")
		fmt.Println(err.Error())
		return VisitorJSON{}, err
	}

	svc := dynamodb.New(sess)

	item = VisitorJSON{
		ID:         guid.String(),
		VisitorNum: 0,
		Message:    fmt.Sprintf("Hello visitor %d", 0),
		Timestamp:  time.Now(),
	}

	av, err := dynamodbattribute.MarshalMap(item)
	if err != nil {
		fmt.Println("Unable to marshal an item:")
		fmt.Println(err.Error())
		return VisitorJSON{}, err
	}
	input := &dynamodb.PutItemInput{
		Item:      av,
		TableName: aws.String(tableName),
	}

	_, err = svc.PutItem(input)
	if err != nil {
		fmt.Println("Got error calling PutItem:")
		fmt.Println(err.Error())
		return VisitorJSON{}, err
	}

	return item, nil
}

// getErrorResponseEvent create and return error via API Gateway
func getErrorResponseEvent(code int, err error) (events.APIGatewayProxyResponse, error) {
	return events.APIGatewayProxyResponse{
		StatusCode: code,
		Body:       err.Error(),
	}, err
}

// Handler handles AWS Lambda function.
func Handler(ctx context.Context, request events.APIGatewayProxyRequest) (response events.APIGatewayProxyResponse, err error) {
	if debug, err := strconv.ParseBool(os.Getenv("DEBUG")); err != nil {
		return getErrorResponseEvent(http.StatusInternalServerError, err)
	} else if err == nil && debug {
		fmt.Println("Build Date:", version.BuildDate)
		fmt.Println("Git Commit:", version.GitCommit)
		fmt.Println("Version:", version.Version)

		fmt.Println("Headers: ")
		if err := PrettyPrint(request.Headers); err != nil {
			return getErrorResponseEvent(http.StatusInternalServerError, err)
		}
	}

	fmt.Printf("Processing request data for request %s.\n", request.RequestContext.RequestID)
	fmt.Printf("Body size = %d.\n", len(request.Body))

	item, err := generateAndRecord()
	if err != nil {
		fmt.Println(err.Error())
		return getErrorResponseEvent(http.StatusInternalServerError, err)
	}

	resp, err := json.Marshal(item)
	if err != nil {
		return getErrorResponseEvent(http.StatusInternalServerError, err)
	}

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Headers:    map[string]string{"X-TEST": "TEST"},
		Body:       string(resp),
	}, nil
}

func main() {
	lambda.Start(Handler)
}
