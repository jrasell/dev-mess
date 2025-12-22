package main

import (
	"sync/atomic"
	"testing"
)

func Benchmark_atomicBoolLoad(b *testing.B) {

	var atomicB atomic.Bool
	atomicB.Store(true)

	for b.Loop() {
		_ = atomicB.Load()
	}
}

func Benchmark_nonAtomicBoolLoad(b *testing.B) {

	var nonAtmicB bool = true

	for b.Loop() {
		_ = nonAtmicB
	}
}
