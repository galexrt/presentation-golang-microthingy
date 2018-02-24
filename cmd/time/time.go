package main

import (
	"fmt"
	"net/http"
	"time"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "The current time is %s", time.Now().Format("3:04PM"))
	})
	http.ListenAndServe(":8080", nil)
}
