package main

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	r := gin.Default()
	r.GET("/", func(c *gin.Context) {
		c.String(http.StatusOK, fmt.Sprintf("The date is %s\n", time.Now().Format(time.RFC3339)))
	})
	r.Run()
}
