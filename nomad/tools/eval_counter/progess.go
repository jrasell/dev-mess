package main

import (
	"fmt"
	"time"
)

type progressTracker struct {
	num int
}

func newProgressTracker() *progressTracker { return &progressTracker{} }

func (p *progressTracker) add() { p.num++ }

func (p *progressTracker) runPeriodicStatus(done chan struct{}) {
	t := time.NewTicker(30 * time.Second)
	for {
		select {
		case <-t.C:
			fmt.Println(fmt.Sprintf("processed %v evaluations", p.num))
		case <-done:
			fmt.Println(fmt.Sprintf("processed total of %v evaluations", p.num))
			return
		}
	}
}
