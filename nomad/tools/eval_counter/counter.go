package main

import (
	"github.com/hashicorp/nomad/api"
)

type counter struct {
	evalTriggeredBy   map[string]int
	evalSchedulerType map[string]int
}

func newCounter() *counter {
	return &counter{
		evalTriggeredBy:   make(map[string]int),
		evalSchedulerType: make(map[string]int),
	}
}

func (c *counter) addEval(eval *api.Evaluation) {
	c.evalTriggeredBy[eval.TriggeredBy]++
	c.evalSchedulerType[eval.Type]++
}
