package main

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sts"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/ec2metadata"
	"github.com/aws/aws-sdk-go/aws/session"
)

func main() {
	http.HandleFunc("/", handlerFunc)
	http.HandleFunc("/old", oldHandlerFunc)
	http.ListenAndServe(":8080", nil)

}

func oldHandlerFunc(res http.ResponseWriter, req *http.Request) {
	sess, err := session.NewSession(&aws.Config{
		LogLevel: aws.LogLevel(aws.LogDebugWithHTTPBody), // リクエスト/レスポンスをログ出力
		Logger:   aws.NewDefaultLogger(),
	})
	if err != nil {
		res.WriteHeader(http.StatusInternalServerError)
		io.WriteString(res, "session error"+err.Error())
		return
	}
	fmt.Println("session created")
	fmt.Printf("%+v\n", sess)
	svc := ec2metadata.New(sess)
	mac, err := svc.GetMetadata("mac")
	if err != nil {
		res.WriteHeader(http.StatusInternalServerError)
		io.WriteString(res, "mac error"+err.Error())
		return
	}
	vpcID, err := svc.GetMetadata(fmt.Sprintf("network/interfaces/macs/%s/vpc-id", mac))
	if err != nil {
		res.WriteHeader(http.StatusInternalServerError)
		io.WriteString(res, "vpc-id error"+err.Error())
		return
	}
	res.Header().Set("Content-Type", "text/plain")
	res.WriteHeader(http.StatusOK)
	io.WriteString(res, vpcID)
}

func handlerFunc(res http.ResponseWriter, req *http.Request) {
	ctx := context.Background()
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		panic("configuration error, " + err.Error())
	}
	stsClient := sts.NewFromConfig(cfg)
	identity, err := stsClient.GetCallerIdentity(ctx, &sts.GetCallerIdentityInput{})

	if err != nil {
		panic("sts get caller identity, " + err.Error())
	}
	body := fmt.Sprintf("Account: %s, ", toSecureString(*identity.Account))
	body += fmt.Sprintf("Arn: %s, ", toSecureString(*identity.Arn))
	body += fmt.Sprintf("UserId: %s", toSecureString(*identity.UserId))

	res.Header().Set("Content-Type", "text/plain")
	res.WriteHeader(http.StatusOK)
	io.WriteString(res, body)
}

func toSecureString(s string) string {
	if len(s) < 4 {
		return strings.Repeat("*", len(s))
	}
	return s[:2] + strings.Repeat("*", len(s)-4) + s[len(s)-2:]
}
