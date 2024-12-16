package main

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"strings"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sts"
)

func main() {
	http.HandleFunc("/", handlerFunc)
	http.ListenAndServe(":8080", nil)

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
