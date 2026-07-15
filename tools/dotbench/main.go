package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
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

func main() {
	runs, err := parseRuns(os.Args[1:])
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(2)
	}

	workDir, err := os.MkdirTemp("", "dotfiles-benchmark.*")
	if err != nil {
		fmt.Fprintf(os.Stderr, "create temporary directory: %v\n", err)
		os.Exit(1)
	}
	defer os.RemoveAll(workDir)

	benchmarks := []benchmark{
		{
			name:    "zsh interactive",
			command: "zsh",
			args:    []string{"-i", "-c", "exit"},
		},
		{
			name:    "nvim headless",
			command: "nvim",
			args:    []string{"--headless", "--cmd", "set shadafile=NONE", "+qa"},
			env:     []string{"NVIM_LOG_FILE=" + filepath.Join(workDir, "nvim.log")},
		},
	}

	for _, b := range benchmarks {
		if _, err := exec.LookPath(b.command); err != nil {
			fmt.Fprintf(os.Stderr, "required command not found: %s\n", b.command)
			os.Exit(1)
		}
		if _, err := run(b); err != nil {
			fmt.Fprintf(os.Stderr, "warm up %s: %v\n", b.name, err)
			os.Exit(1)
		}
	}

	results := make([][]time.Duration, len(benchmarks))
	for i := 0; i < runs; i++ {
		for j, b := range benchmarks {
			duration, err := run(b)
			if err != nil {
				fmt.Fprintf(os.Stderr, "benchmark %s: %v\n", b.name, err)
				os.Exit(1)
			}
			results[j] = append(results[j], duration)
		}
	}

	fmt.Printf("Startup benchmark (%d runs, one warm-up; lower is better)\n", runs)
	for i, b := range benchmarks {
		printSummary(b.name, results[i])
	}
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

func printSummary(name string, durations []time.Duration) {
	sorted := append([]time.Duration(nil), durations...)
	sort.Slice(sorted, func(i, j int) bool { return sorted[i] < sorted[j] })

	var total time.Duration
	for _, duration := range sorted {
		total += duration
	}

	median := sorted[len(sorted)/2]
	if len(sorted)%2 == 0 {
		median = (sorted[len(sorted)/2-1] + sorted[len(sorted)/2]) / 2
	}

	fmt.Printf(
		"%-16s min %8.3f ms  median %8.3f ms  mean %8.3f ms  max %8.3f ms\n",
		name,
		milliseconds(sorted[0]),
		milliseconds(median),
		milliseconds(total/time.Duration(len(sorted))),
		milliseconds(sorted[len(sorted)-1]),
	)
}

func milliseconds(duration time.Duration) float64 {
	return float64(duration) / float64(time.Millisecond)
}
