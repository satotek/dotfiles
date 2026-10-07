package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"time"

	"github.com/spf13/cobra"
)

var version = "dev"

type report struct {
	Schema      int                        `json:"schema"`
	Mode        string                     `json:"mode"`
	Runs        int                        `json:"runs"`
	Warmup      int                        `json:"warmup"`
	Created     time.Time                  `json:"created"`
	Samples     map[string][]time.Duration `json:"samples_ns"`
	Environment *environment               `json:"environment,omitempty"`
}

type executableInfo struct {
	Path    string `json:"path"`
	Version string `json:"version"`
}

type environment struct {
	OS          string                    `json:"os"`
	Arch        string                    `json:"arch"`
	Host        string                    `json:"host"`
	CPU         string                    `json:"cpu"`
	CPUs        int                       `json:"logical_cpus"`
	Executables map[string]executableInfo `json:"executables"`
}

type startupOptions struct {
	runs     int
	warmup   int
	only     string
	output   string
	baseline string
	zshPath  string
	nvimPath string
}

func main() {
	if err := newCommand().Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func newCommand() *cobra.Command {
	var opts startupOptions
	cmd := &cobra.Command{
		Use:           "dotbench [runs]",
		Short:         "Measure zsh and Neovim startup latency",
		Version:       version,
		SilenceUsage:  true,
		SilenceErrors: true,
		Args:          cobra.MaximumNArgs(1),
		Example: strings.Join([]string{
			"  dotbench 50",
			"  dotbench --only zsh --runs 100 --output before.json",
			"  dotbench --only zsh --compare before.json",
		}, "\n"),
		RunE: func(cmd *cobra.Command, args []string) error {
			if len(args) > 0 {
				if cmd.Flags().Changed("runs") {
					return fmt.Errorf("use either positional runs or --runs")
				}
				n, err := parseRuns(args)
				if err != nil {
					return err
				}
				opts.runs = n
			}
			return runStartup(cmd.OutOrStdout(), cmd.ErrOrStderr(), opts)
		},
	}

	flags := cmd.Flags()
	flags.IntVarP(&opts.runs, "runs", "n", defaultRuns, "Number of measured runs")
	flags.IntVar(&opts.warmup, "warmup", 1, "Number of unmeasured warm-up runs")
	flags.StringVar(&opts.only, "only", "all", "Target: all, zsh, or nvim")
	flags.StringVarP(&opts.output, "output", "o", "", "Save JSON samples (must be a new file)")
	flags.StringVar(&opts.baseline, "compare", "", "Compare medians against saved startup JSON")
	flags.StringVar(&opts.zshPath, "zsh", "zsh", "zsh executable name or path (startup mode)")
	flags.StringVar(&opts.nvimPath, "nvim", "nvim", "Neovim executable name or path (startup mode)")
	_ = cmd.MarkFlagFilename("zsh")
	_ = cmd.MarkFlagFilename("nvim")
	_ = cmd.RegisterFlagCompletionFunc("only", func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
		return []string{
			"all\tBoth targets",
			"zsh\tInteractive startup",
			"nvim\tHeadless startup",
		}, cobra.ShellCompDirectiveNoFileComp
	})
	cmd.ValidArgsFunction = func(_ *cobra.Command, args []string, _ string) ([]string, cobra.ShellCompDirective) {
		if len(args) > 0 {
			return nil, cobra.ShellCompDirectiveNoFileComp
		}
		return []string{
			"10\tQuick measurement",
			"50\tStandard measurement",
			"100\tLonger measurement",
		}, cobra.ShellCompDirectiveNoFileComp
	}

	cmd.AddCommand(interactiveCommand())
	return cmd
}

func runStartup(stdout, stderr io.Writer, opts startupOptions) (err error) {
	if opts.runs < 1 || opts.warmup < 0 {
		return fmt.Errorf("runs must be positive and warmup non-negative")
	}
	if opts.only != "all" && opts.only != "zsh" && opts.only != "nvim" {
		return fmt.Errorf("unknown target %q", opts.only)
	}

	var previous *report
	if opts.baseline != "" {
		if previous, err = loadBaseline(opts.baseline, "startup", opts.warmup); err != nil {
			return err
		}
	}

	out, err := createOutput(opts.output)
	if err != nil {
		return err
	}
	defer func() { err = out.close(err) }()

	dir, err := os.MkdirTemp("", "dotbench-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(dir)

	var targets []benchmark
	for _, b := range []benchmark{
		{name: "zsh", command: opts.zshPath, args: []string{"-i", "-c", "exit"}},
		{
			name:    "nvim",
			command: opts.nvimPath,
			args:    []string{"--headless", "--cmd", "set shadafile=NONE", "+qa"},
			env:     []string{"NVIM_LOG_FILE=" + filepath.Join(dir, "nvim.log")},
		},
	} {
		if opts.only == "all" || opts.only == b.name {
			targets = append(targets, b)
		}
	}

	result := report{
		Schema:      1,
		Mode:        "startup",
		Runs:        opts.runs,
		Warmup:      opts.warmup,
		Created:     time.Now().UTC(),
		Samples:     map[string][]time.Duration{},
		Environment: currentEnvironment(),
	}
	for i := range targets {
		b := &targets[i]
		if previous != nil && len(previous.Samples[b.name]) == 0 {
			return fmt.Errorf("baseline has no %s samples", b.name)
		}
		resolved, info, err := resolveExecutable(b.command)
		if err != nil {
			return fmt.Errorf("%s executable: %w", b.name, err)
		}
		b.command = resolved
		result.Environment.Executables[b.name] = info
	}
	if previous != nil {
		warnEnvironment(stderr, previous.Environment, result.Environment)
	}

	for _, b := range targets {
		samples, err := measure(b, opts.warmup, opts.runs)
		if err != nil {
			return fmt.Errorf("%s: %w", b.name, err)
		}
		result.Samples[b.name] = samples
	}

	title := fmt.Sprintf("Startup benchmark (%d runs, %d warm-ups; lower is better)", opts.runs, opts.warmup)
	printReport(stdout, title, targetNames(targets), &result, previous)
	return out.write(&result)
}

func targetNames(targets []benchmark) []string {
	names := make([]string, 0, len(targets))
	for _, b := range targets {
		names = append(names, b.name)
	}
	return names
}

func printReport(w io.Writer, title string, names []string, result, previous *report) {
	fmt.Fprintln(w, title)
	for _, name := range names {
		samples := result.Samples[name]
		printSummary(w, name, samples)
		if previous != nil {
			before := medianMS(previous.Samples[name])
			fmt.Fprintf(w, "  median change: %+.2f%%\n", 100*(medianMS(samples)/before-1))
		}
	}
}

// 結果ファイルは計測の前に作る。計測後に「既に存在する」で失敗すると、長い計測が無駄になるため。
type outputFile struct {
	path string
	file *os.File
}

func createOutput(path string) (*outputFile, error) {
	if path == "" {
		return nil, nil
	}
	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		return nil, err
	}
	return &outputFile{path: path, file: file}, nil
}

func (o *outputFile) write(result *report) error {
	if o == nil {
		return nil
	}
	data, err := json.MarshalIndent(result, "", "  ")
	if err != nil {
		return err
	}
	_, err = o.file.Write(append(data, '\n'))
	return err
}

func (o *outputFile) close(err error) error {
	if o == nil {
		return err
	}
	if closeErr := o.file.Close(); err == nil {
		err = closeErr
	}
	// 空のファイルが残ると、次回の同名指定が O_EXCL で弾かれる。
	if err != nil {
		os.Remove(o.path)
	}
	return err
}

func loadBaseline(path, mode string, warmup int) (*report, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	var previous report
	if err := json.Unmarshal(data, &previous); err != nil {
		return nil, err
	}
	if previous.Schema != 1 || previous.Mode != mode {
		return nil, fmt.Errorf("incompatible baseline: want %s results", mode)
	}
	if previous.Warmup != warmup {
		return nil, fmt.Errorf("baseline warmup differs")
	}
	for name, samples := range previous.Samples {
		if len(samples) > 0 && medianMS(samples) <= 0 {
			return nil, fmt.Errorf("invalid baseline median for %s", name)
		}
	}
	return &previous, nil
}

// 計測には PATH で見つけたパスを使い、記録には実体のパスを残す。
// Nix の profile 経由のリンクは更新後も同じパスのままなので、比較では実体で判別する。
func resolveExecutable(command string) (string, executableInfo, error) {
	resolved, err := exec.LookPath(command)
	if err != nil {
		return "", executableInfo{}, err
	}
	if resolved, err = filepath.Abs(resolved); err != nil {
		return "", executableInfo{}, err
	}
	real, err := filepath.EvalSymlinks(resolved)
	if err != nil {
		return "", executableInfo{}, err
	}
	return resolved, executableInfo{Path: real, Version: commandLine(resolved, "--version")}, nil
}

func measure(b benchmark, warmup, runs int) ([]time.Duration, error) {
	samples := make([]time.Duration, 0, runs)
	for i := 0; i < warmup+runs; i++ {
		d, err := run(b)
		if err != nil {
			return nil, err
		}
		if i >= warmup {
			samples = append(samples, d)
		}
	}
	return samples, nil
}

// 計測区間の外で呼ぶこと。版の取得にかかる時間をサンプルに含めないため。
func commandLine(path string, args ...string) string {
	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()
	data, err := exec.CommandContext(ctx, path, args...).Output()
	if err != nil {
		return "unknown"
	}
	line, _, _ := strings.Cut(strings.TrimSpace(string(data)), "\n")
	if line == "" {
		return "unknown"
	}
	return line
}

func currentEnvironment() *environment {
	host, _ := os.Hostname()
	cpu := "unknown"
	switch runtime.GOOS {
	case "linux":
		if data, err := os.ReadFile("/proc/cpuinfo"); err == nil {
			for line := range strings.SplitSeq(string(data), "\n") {
				key, value, ok := strings.Cut(line, ":")
				if ok && strings.TrimSpace(key) == "model name" {
					cpu = strings.TrimSpace(value)
					break
				}
			}
		}
	case "darwin":
		cpu = commandLine("/usr/sbin/sysctl", "-n", "machdep.cpu.brand_string")
	}
	return &environment{
		OS:          runtime.GOOS,
		Arch:        runtime.GOARCH,
		Host:        host,
		CPU:         cpu,
		CPUs:        runtime.NumCPU(),
		Executables: map[string]executableInfo{},
	}
}

func warnEnvironment(w io.Writer, old, current *environment) {
	if old == nil {
		fmt.Fprintln(w, "Warning: baseline has no environment metadata; comparability cannot be checked.")
		return
	}
	if old.OS != current.OS || old.Arch != current.Arch || old.Host != current.Host ||
		old.CPU != current.CPU || old.CPUs != current.CPUs {
		fmt.Fprintln(w, "Warning: baseline machine/OS/CPU differs; latency changes may not come from configuration alone.")
	}
	for _, name := range []string{"zsh", "nvim"} {
		info, selected := current.Executables[name]
		if !selected {
			continue
		}
		before, exists := old.Executables[name]
		if !exists || before != info {
			fmt.Fprintf(w, "Warning: %s executable path/version differs from baseline.\n", name)
		}
		if info.Version == "unknown" {
			fmt.Fprintf(w, "Warning: %s version could not be detected.\n", name)
		}
	}
}
