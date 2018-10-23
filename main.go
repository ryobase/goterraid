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
	"github.com/json-iterator/go"
	"github.com/rs/xid"
	"github.com/ryobase/goterraid/version"
)

var json = jsoniter.ConfigCompatibleWithStandardLibrary

// VisitorJSON is response model
type VisitorJSON struct {
	ID         string    `json:"id"`
	VisitorNum int64     `json:"visitor_number"`
	Message    string    `json:"message"`
	Timestamp  time.Time `json:"timestamp"`
}

// PrettyPrint will pretty print variable (struct, map, array, slice).
func PrettyPrint(v interface{}) (err error) {
	b, err := json.MarshalIndent(v, "", "  ")
	if err == nil {
		fmt.Println(string(b))
	}
	return
}

// GenerateAndRecord will generate a new UUID and put it a database table before return it.
func GenerateAndRecord() {
	guid := xid.New()
	fmt.Println(guid.String())
}

// Handler handles AWS Lambda function.
func Handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	if debug, err := strconv.ParseBool(os.Getenv("DEBUG")); err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       http.StatusText(http.StatusInternalServerError),
		}, err
	} else if err == nil && debug {
		fmt.Println("Build Date:", version.BuildDate)
		fmt.Println("Git Commit:", version.GitCommit)
		fmt.Println("Version:", version.Version)

		fmt.Println("Headers: ")
		if err := PrettyPrint(request.Headers); err != nil {
			return events.APIGatewayProxyResponse{
				StatusCode: http.StatusInternalServerError,
				Body:       http.StatusText(http.StatusInternalServerError),
			}, err
		}
	}

	fmt.Printf("Processing request data for request %s.\n", request.RequestContext.RequestID)
	fmt.Printf("Body size = %d.\n", len(request.Body))

	resp, err := json.Marshal(VisitorJSON{
		ID:         xid.New().String(),
		VisitorNum: 0,
		Message:    fmt.Sprintf("Hello visitor#%d", 0),
		Timestamp:  time.Now(),
	})
	if err != nil {
		return events.APIGatewayProxyResponse{
			StatusCode: http.StatusInternalServerError,
			Body:       http.StatusText(http.StatusInternalServerError),
		}, err
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
