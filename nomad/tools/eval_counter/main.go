package main

import "github.com/davecgh/go-spew/spew"

func main() {

	stream := newJSONStream()
	count := newCounter()

	progress := newProgressTracker()
	doneCh := make(chan struct{})
	go progress.runPeriodicStatus(doneCh)

	go func() {
		for data := range stream.Watch() {
			if data.error != nil {
				panic(data.error)
			}
			count.addEval(data.eval)
			progress.add()
		}
	}()
	stream.Start("")
	doneCh <- struct{}{}
	close(doneCh)
	spew.Dump(count.evalTriggeredBy)
	spew.Dump(count.evalSchedulerType)
}
