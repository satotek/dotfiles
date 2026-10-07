package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"slices"
	"strconv"
	"time"
)

const defaultRuns = 10

type benchmark struct {
	name    string
	command string
	args    []string
	env     []string
}

func parseRuns(args []string) (int, error) {
	if len(args) > 1 {
		return 0, fmt.Errorf("usage: dotbench [positive-number-of-runs]")
	}
	if len(args) == 0 {
		return defaultRuns, nil
	}

	runs, err := strconv.Atoi(args[0])
	if err != nil || runs < 1 {
		return 0, fmt.Errorf("number of runs must be a positive integer")
	}
	return runs, nil
}

func run(b benchmark) (time.Duration, error) {
	cmd := exec.Command(b.command, b.args...)
	cmd.Stdout = io.Discard
	cmd.Stderr = io.Discard
	cmd.Env = append(os.Environ(), b.env...)

	start := time.Now()
	err := cmd.Run()
	return time.Since(start), err
}

func sortedCopy(samples []time.Duration) []time.Duration {
	sorted := slices.Clone(samples)
	slices.Sort(sorted)
	return sorted
}

func medianMS(samples []time.Duration) float64 {
	sorted := sortedCopy(samples)
	n := len(sorted)
	if n%2 == 0 {
		return milliseconds((sorted[n/2-1] + sorted[n/2]) / 2)
	}
	return milliseconds(sorted[n/2])
}

func printSummary(w io.Writer, name string, samples []time.Duration) {
	sorted := sortedCopy(samples)

	var total time.Duration
	for _, duration := range sorted {
		total += duration
	}

	fmt.Fprintf(
		w,
		"%-16s min %8.3f ms  median %8.3f ms  mean %8.3f ms  max %8.3f ms\n",
		name,
		milliseconds(sorted[0]),
		medianMS(sorted),
		milliseconds(total/time.Duration(len(sorted))),
		milliseconds(sorted[len(sorted)-1]),
	)
}

func milliseconds(duration time.Duration) float64 {
	return float64(duration) / float64(time.Millisecond)
}
