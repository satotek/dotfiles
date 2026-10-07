package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/creack/pty"
	"github.com/spf13/cobra"
)

// 端末は未知の OSC を表示せずに捨てるので、普段の画面を汚さずに目印として使える。
const promptMarker = "\x1b]9999;dotbench-prompt\a"

const (
	promptTimeout = 15 * time.Second
	// zsh-defer などの遅延読み込みは最初のプロンプトの後に走る。
	// それが終わる前に測ると、定常時の応答ではなく読み込み待ちを測ってしまう。
	settleDelay = time.Second
)

var interactiveMetrics = []string{"first_prompt", "first_command", "command", "exit"}

// 本来の起動ファイルを読み込んだ後に、プロンプトの目印を出すフックを足す。
// プロンプトの中身を探す方式だと、テーマを変えるたびに検出が壊れる。
const wrapperZshenv = `typeset -g _dotbench_wrapper_dir=$ZDOTDIR
ZDOTDIR=$_DOTBENCH_ZDOTDIR
unset _DOTBENCH_ZDOTDIR
[[ -r $ZDOTDIR/.zshenv ]] && builtin source $ZDOTDIR/.zshenv
typeset -g _dotbench_user_dir=$ZDOTDIR
ZDOTDIR=$_dotbench_wrapper_dir
`

const wrapperZshrc = `ZDOTDIR=$_dotbench_user_dir
unset _dotbench_wrapper_dir _dotbench_user_dir
[[ -r $ZDOTDIR/.zshrc ]] && builtin source $ZDOTDIR/.zshrc
_dotbench_prompt_marker() { print -rn -- $'\e]9999;dotbench-prompt\a' >$TTY }
zmodload zsh/zle
autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init _dotbench_prompt_marker
setopt no_ignore_eof
`

type interactiveOptions struct {
	runs     int
	warmup   int
	output   string
	baseline string
	zshPath  string
}

func interactiveCommand() *cobra.Command {
	var opts interactiveOptions
	cmd := &cobra.Command{
		Use:   "interactive",
		Short: "Measure zsh prompt, command and exit latency in a pseudo-terminal",
		Long: strings.Join([]string{
			"Run zsh in a pseudo-terminal with your configuration and measure:",
			"  first_prompt   start until the first prompt is ready for input",
			"  first_command  start until a command typed immediately has finished",
			"  command        Enter on an empty line until the next prompt (after deferred loading)",
			"  exit           Ctrl-D until the process exits",
			"Only empty lines are entered, so nothing is added to shell history.",
			"Uses non-login shells. Keystroke and Tab latency are not measured.",
		}, "\n"),
		Args: cobra.NoArgs,
		RunE: func(cmd *cobra.Command, _ []string) error {
			return runInteractive(cmd.OutOrStdout(), cmd.ErrOrStderr(), opts)
		},
	}
	flags := cmd.Flags()
	flags.IntVarP(&opts.runs, "runs", "n", defaultRuns, "Number of measured runs")
	flags.IntVar(&opts.warmup, "warmup", 1, "Number of unmeasured warm-up runs")
	flags.StringVarP(&opts.output, "output", "o", "", "Save JSON samples (must be a new file)")
	flags.StringVar(&opts.baseline, "compare", "", "Compare medians against saved interactive JSON")
	flags.StringVar(&opts.zshPath, "zsh", "zsh", "zsh executable name or path")
	_ = cmd.MarkFlagFilename("zsh")
	return cmd
}

func runInteractive(stdout, stderr io.Writer, opts interactiveOptions) (err error) {
	if opts.runs < 1 || opts.warmup < 0 {
		return fmt.Errorf("runs must be positive and warmup non-negative")
	}

	var previous *report
	if opts.baseline != "" {
		if previous, err = loadBaseline(opts.baseline, "interactive", opts.warmup); err != nil {
			return err
		}
		for _, name := range interactiveMetrics {
			if len(previous.Samples[name]) == 0 {
				return fmt.Errorf("baseline has no %s samples", name)
			}
		}
	}

	out, err := createOutput(opts.output)
	if err != nil {
		return err
	}
	defer func() { err = out.close(err) }()

	zsh, info, err := resolveExecutable(opts.zshPath)
	if err != nil {
		return fmt.Errorf("zsh executable: %w", err)
	}
	result := report{
		Schema:      1,
		Mode:        "interactive",
		Runs:        opts.runs,
		Warmup:      opts.warmup,
		Created:     time.Now().UTC(),
		Samples:     map[string][]time.Duration{},
		Environment: currentEnvironment(),
	}
	result.Environment.Executables["zsh"] = info
	if previous != nil {
		warnEnvironment(stderr, previous.Environment, result.Environment)
	}

	dir, err := os.MkdirTemp("", "dotbench-")
	if err != nil {
		return err
	}
	defer os.RemoveAll(dir)
	env, err := wrapperEnv(dir)
	if err != nil {
		return err
	}

	for i := 0; i < opts.warmup+opts.runs; i++ {
		samples, err := measureInteractive(zsh, env)
		if err != nil {
			return err
		}
		if i < opts.warmup {
			continue
		}
		for _, name := range interactiveMetrics {
			result.Samples[name] = append(result.Samples[name], samples[name])
		}
	}

	title := fmt.Sprintf("Interactive zsh benchmark (%d runs, %d warm-ups; lower is better)", opts.runs, opts.warmup)
	printReport(stdout, title, interactiveMetrics, &result, previous)
	return out.write(&result)
}

func wrapperEnv(dir string) ([]string, error) {
	for name, content := range map[string]string{".zshenv": wrapperZshenv, ".zshrc": wrapperZshrc} {
		if err := os.WriteFile(filepath.Join(dir, name), []byte(content), 0600); err != nil {
			return nil, err
		}
	}
	userDir := os.Getenv("ZDOTDIR")
	if userDir == "" {
		userDir = os.Getenv("HOME")
	}
	// 実際の端末の TERM は環境ごとに異なり、terminfo が無いと描画が変わるため揃える。
	return append(os.Environ(), "TERM=xterm-256color", "ZDOTDIR="+dir, "_DOTBENCH_ZDOTDIR="+userDir), nil
}

func measureInteractive(zsh string, env []string) (map[string]time.Duration, error) {
	samples := map[string]time.Duration{}

	s, start, err := startShell(zsh, env)
	if err != nil {
		return nil, err
	}
	defer s.close()
	ready, err := s.waitPrompt("first prompt")
	if err != nil {
		return nil, err
	}
	samples["first_prompt"] = ready.Sub(start)

	time.Sleep(settleDelay)
	s.discardPrompts()
	sent, err := s.send("\r")
	if err != nil {
		return nil, err
	}
	ready, err = s.waitPrompt("prompt after Enter")
	if err != nil {
		return nil, err
	}
	samples["command"] = ready.Sub(sent)

	if sent, err = s.send("\x04"); err != nil {
		return nil, err
	}
	exited, err := s.waitExit()
	if err != nil {
		return nil, err
	}
	samples["exit"] = exited.Sub(sent)

	// 起動直後に打った Enter は、起動処理が終わるまで実行されない。
	// プロンプトが出ていても待たされる時間は、この値にだけ現れる。
	s2, start, err := startShell(zsh, env)
	if err != nil {
		return nil, err
	}
	defer s2.close()
	if _, err := s2.send("\r"); err != nil {
		return nil, err
	}
	for _, label := range []string{"first prompt", "prompt after the typed-ahead Enter"} {
		if ready, err = s2.waitPrompt(label); err != nil {
			return nil, err
		}
	}
	samples["first_command"] = ready.Sub(start)
	if _, err := s2.send("\x04"); err != nil {
		return nil, err
	}
	if _, err := s2.waitExit(); err != nil {
		return nil, err
	}
	return samples, nil
}

type shell struct {
	cmd     *exec.Cmd
	pty     *os.File
	prompts chan time.Time
	tail    *tailBuffer

	// waitErr と exitedAt は done が閉じた後にだけ読む。
	done     chan struct{}
	waitErr  error
	exitedAt time.Time
}

func startShell(zsh string, env []string) (*shell, time.Time, error) {
	cmd := exec.Command(zsh, "-i")
	cmd.Env = env
	start := time.Now()
	f, err := pty.StartWithSize(cmd, &pty.Winsize{Rows: 40, Cols: 120})
	if err != nil {
		return nil, start, fmt.Errorf("start zsh in a pseudo-terminal: %w", err)
	}
	s := &shell{
		cmd:     cmd,
		pty:     f,
		prompts: make(chan time.Time, 64),
		tail:    &tailBuffer{},
		done:    make(chan struct{}),
	}
	go s.read()
	go func() {
		s.waitErr = cmd.Wait()
		s.exitedAt = time.Now()
		close(s.done)
	}()
	return s, start, nil
}

// 出力は止めずに読み続ける。読まないと zsh の書き込みが詰まり、遅延として計測されてしまう。
func (s *shell) read() {
	marker := []byte(promptMarker)
	buf := make([]byte, 32*1024)
	var pending []byte
	for {
		n, err := s.pty.Read(buf)
		if n > 0 {
			now := time.Now()
			s.tail.write(buf[:n])
			pending = append(pending, buf[:n]...)
			for {
				i := bytes.Index(pending, marker)
				if i < 0 {
					break
				}
				s.prompts <- now
				pending = pending[i+len(marker):]
			}
			// 目印が読み込みの境目で分かれても見つけられるよう、末尾だけ残す。
			if keep := len(marker) - 1; len(pending) > keep {
				pending = append([]byte(nil), pending[len(pending)-keep:]...)
			}
		}
		if err != nil {
			return
		}
	}
}

func (s *shell) send(keys string) (time.Time, error) {
	sent := time.Now()
	_, err := s.pty.WriteString(keys)
	return sent, err
}

func (s *shell) waitPrompt(label string) (time.Time, error) {
	select {
	case t := <-s.prompts:
		return t, nil
	case <-s.done:
		return time.Time{}, fmt.Errorf("zsh exited while waiting for the %s (%v); last output: %q", label, s.waitErr, s.tail.String())
	case <-time.After(promptTimeout):
		return time.Time{}, fmt.Errorf("timed out waiting for the %s; last output: %q", label, s.tail.String())
	}
}

func (s *shell) discardPrompts() {
	for {
		select {
		case <-s.prompts:
		default:
			return
		}
	}
}

func (s *shell) waitExit() (time.Time, error) {
	select {
	case <-s.done:
		var exitErr *exec.ExitError
		if s.waitErr != nil && !errors.As(s.waitErr, &exitErr) {
			return s.exitedAt, s.waitErr
		}
		return s.exitedAt, nil
	case <-time.After(promptTimeout):
		return time.Time{}, fmt.Errorf("timed out waiting for zsh to exit; last output: %q", s.tail.String())
	}
}

func (s *shell) close() {
	select {
	case <-s.done:
	default:
		_ = s.cmd.Process.Kill()
		<-s.done
	}
	_ = s.pty.Close()
}

// 失敗時の手がかりとして、直近の出力だけを保持する。
type tailBuffer struct {
	mu   sync.Mutex
	data []byte
}

const tailSize = 512

func (b *tailBuffer) write(p []byte) {
	b.mu.Lock()
	defer b.mu.Unlock()
	b.data = append(b.data, p...)
	if len(b.data) > tailSize {
		b.data = append([]byte(nil), b.data[len(b.data)-tailSize:]...)
	}
}

func (b *tailBuffer) String() string {
	b.mu.Lock()
	defer b.mu.Unlock()
	return string(b.data)
}
