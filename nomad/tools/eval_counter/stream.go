package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/hashicorp/nomad/api"
)

type entry struct {
	error error
	eval  *api.Evaluation
}

type stream struct {
	stream chan entry
}

func newJSONStream() stream {
	return stream{
		stream: make(chan entry),
	}
}

func (s stream) Watch() <-chan entry {
	return s.stream
}

func (s stream) Start(path string) {
	defer close(s.stream)

	file, err := os.Open(path)
	if err != nil {
		s.stream <- entry{error: fmt.Errorf("open file: %w", err)}
		return
	}
	defer file.Close()

	decoder := json.NewDecoder(file)

	if _, err := decoder.Token(); err != nil {
		s.stream <- entry{error: fmt.Errorf("decode opening delimiter: %w", err)}
		return
	}

	i := 1
	for decoder.More() {
		var e api.Evaluation
		if err := decoder.Decode(&e); err != nil {
			s.stream <- entry{error: fmt.Errorf("decode line %d: %w", i, err)}
			return
		}
		s.stream <- entry{eval: &e}
		i++
	}

	if _, err := decoder.Token(); err != nil {
		s.stream <- entry{error: fmt.Errorf("decode closing delimiter: %w", err)}
		return
	}
}
