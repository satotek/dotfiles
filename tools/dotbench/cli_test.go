package main

import (
	"bytes"
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestCLI(t *testing.T) {
	for _, tc := range []struct {
		args []string
		want string
		fail bool
	}{
		{[]string{"--help"}, "--warmup", false},
		{[]string{"--version"}, "dev", false},
		{[]string{"completion", "zsh"}, "#compdef dotbench", false},
		{[]string{"--runs", "0"}, "", true},
		{[]string{"--warmup", "-1"}, "", true},
		{[]string{"5", "--runs", "5"}, "", true},
		{[]string{"--only", "bad"}, "", true},
	} {
		t.Run(strings.Join(tc.args, " "), func(t *testing.T) {
			cmd := newCommand()
			var buf bytes.Buffer
			cmd.SetOut(&buf)
			cmd.SetErr(&buf)
			cmd.SetArgs(tc.args)
			err := cmd.Execute()
			if (err != nil) != tc.fail {
				t.Fatalf("error: %v", err)
			}
			if !strings.Contains(buf.String(), tc.want) {
				t.Fatalf("output: %s", buf.String())
			}
		})
	}
}

func TestEnvironmentWarnings(t *testing.T) {
	current := &environment{OS: "linux", Arch: "amd64", Host: "test", CPU: "cpu", CPUs: 2, Executables: map[string]executableInfo{"zsh": {Path: "/bin/zsh", Version: "zsh 5.9"}}}
	var buf bytes.Buffer
	warnEnvironment(&buf, nil, current)
	if !strings.Contains(buf.String(), "no environment metadata") {
		t.Fatal(buf.String())
	}
	buf.Reset()
	warnEnvironment(&buf, current, current)
	if buf.Len() != 0 {
		t.Fatal(buf.String())
	}
	old := *current
	old.Host = "other"
	old.Executables = map[string]executableInfo{"zsh": {Path: "/old/zsh", Version: "zsh 5.8"}}
	warnEnvironment(&buf, &old, current)
	if !strings.Contains(buf.String(), "machine/OS/CPU differs") || !strings.Contains(buf.String(), "path/version differs") {
		t.Fatal(buf.String())
	}
}

func TestCustomExecutableAndReport(t *testing.T) {
	// Use a disposable executable instead of a user's shell configuration.
	dir := t.TempDir()
	script := filepath.Join(dir, "test-zsh")
	if err := os.WriteFile(script, []byte("#!/bin/sh\nif [ \"$1\" = --version ]; then echo 'test-zsh 1'; fi\n"), 0700); err != nil {
		t.Fatal(err)
	}
	output := filepath.Join(dir, "result.json")
	cmd := newCommand()
	var buf bytes.Buffer
	cmd.SetOut(&buf)
	cmd.SetErr(&buf)
	cmd.SetArgs([]string{"--only", "zsh", "--zsh", script, "--runs", "2", "--warmup", "0", "--output", output})
	if err := cmd.Execute(); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(output)
	if err != nil {
		t.Fatal(err)
	}
	var saved report
	if err := json.Unmarshal(data, &saved); err != nil {
		t.Fatal(err)
	}
	if len(saved.Samples["zsh"]) != 2 || saved.Environment == nil || saved.Environment.Executables["zsh"].Version != "test-zsh 1" {
		t.Fatalf("report: %+v", saved)
	}
	cmd = newCommand()
	buf.Reset()
	cmd.SetOut(&buf)
	cmd.SetErr(&buf)
	cmd.SetArgs([]string{"--only", "zsh", "--zsh", script, "--runs", "1", "--warmup", "0", "--compare", output})
	if err := cmd.Execute(); err != nil {
		t.Fatal(err)
	}
	if strings.Contains(buf.String(), "Warning:") || !strings.Contains(buf.String(), "median change") {
		t.Fatal(buf.String())
	}
}

func TestExistingOutputFailsBeforeMeasuring(t *testing.T) {
	dir := t.TempDir()
	marker := filepath.Join(dir, "ran")
	script := filepath.Join(dir, "test-zsh")
	if err := os.WriteFile(script, []byte("#!/bin/sh\ntouch '"+marker+"'\n"), 0700); err != nil {
		t.Fatal(err)
	}
	output := filepath.Join(dir, "result.json")
	if err := os.WriteFile(output, nil, 0600); err != nil {
		t.Fatal(err)
	}
	cmd := newCommand()
	cmd.SetOut(&bytes.Buffer{})
	cmd.SetErr(&bytes.Buffer{})
	cmd.SetArgs([]string{"--only", "zsh", "--zsh", script, "--output", output})
	if err := cmd.Execute(); err == nil {
		t.Fatal("expected an error for an existing output file")
	}
	if _, err := os.Stat(marker); !os.IsNotExist(err) {
		t.Fatal("benchmark ran before the output file was checked")
	}
}

func TestFailedRunRemovesOutput(t *testing.T) {
	dir := t.TempDir()
	script := filepath.Join(dir, "test-zsh")
	if err := os.WriteFile(script, []byte("#!/bin/sh\n[ \"$1\" = --version ] || exit 1\n"), 0700); err != nil {
		t.Fatal(err)
	}
	output := filepath.Join(dir, "result.json")
	cmd := newCommand()
	cmd.SetOut(&bytes.Buffer{})
	cmd.SetErr(&bytes.Buffer{})
	cmd.SetArgs([]string{"--only", "zsh", "--zsh", script, "--output", output})
	if err := cmd.Execute(); err == nil {
		t.Fatal("expected the failing benchmark to return an error")
	}
	if _, err := os.Stat(output); !os.IsNotExist(err) {
		t.Fatal("an empty output file was left behind")
	}
}

func TestMedian(t *testing.T) {
	samples := []time.Duration{3 * time.Millisecond, time.Millisecond, 2 * time.Millisecond, 4 * time.Millisecond}
	if got := medianMS(samples); got != 2.5 {
		t.Fatalf("median=%v", got)
	}
	if samples[0] != 3*time.Millisecond {
		t.Fatal("modified input")
	}
}
