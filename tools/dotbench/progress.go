package main

import (
	"fmt"
	"io"
	"os"
	"strings"
	"time"
)

// 描画は計測の合間にだけ行う。別 goroutine でスピナーを回すと、計測中に端末が再描画して数値が揺れる。
// 端末側の描画も非同期に CPU を使うので、短い計測が続くときは間引く。
const progressInterval = 100 * time.Millisecond

const barWidth = 24

var spinnerFrames = []string{"⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"}

type progress struct {
	w        io.Writer
	color    bool
	total    int
	done     int
	start    time.Time
	lastDraw time.Time
	frame    int
}

// 端末でないとき（パイプ、CI、テスト）は nil を返し、何も表示しない。
func newProgress(w io.Writer, total int) *progress {
	f, ok := w.(*os.File)
	if !ok || os.Getenv("TERM") == "dumb" {
		return nil
	}
	info, err := f.Stat()
	if err != nil || info.Mode()&os.ModeCharDevice == 0 {
		return nil
	}
	_, noColor := os.LookupEnv("NO_COLOR")
	return &progress{w: w, color: !noColor, total: total, start: time.Now()}
}

// 計測を 1 回終えるたびに呼ぶ。label は対象名、detail は直前の結果。
func (p *progress) step(label string, warmup bool, detail string) {
	if p == nil {
		return
	}
	p.done++
	if p.done < p.total && time.Since(p.lastDraw) < progressInterval {
		return
	}
	p.draw(label, warmup, detail)
}

// 1 回目の計測が終わるまで何も出ないと、止まっているように見えるため最初に描く。
func (p *progress) begin(label string) {
	if p == nil {
		return
	}
	p.draw(label, true, "")
}

func (p *progress) draw(label string, warmup bool, detail string) {
	p.lastDraw = time.Now()
	p.frame = (p.frame + 1) % len(spinnerFrames)

	filled := barWidth * p.done / p.total
	bar := p.paint("36", strings.Repeat("█", filled)) + p.paint("2", strings.Repeat("░", barWidth-filled))

	parts := []string{
		p.paint("36", spinnerFrames[p.frame]) + " " + p.paint("1", fmt.Sprintf("%-12s", label)),
		bar,
		p.paint("1", fmt.Sprintf("%*d/%d", len(fmt.Sprint(p.total)), p.done, p.total)),
	}
	var notes []string
	if warmup {
		notes = append(notes, "warm-up")
	}
	if detail != "" {
		notes = append(notes, detail)
	}
	if p.done > 0 && p.done < p.total {
		elapsed := time.Since(p.start)
		left := elapsed / time.Duration(p.done) * time.Duration(p.total-p.done)
		notes = append(notes, formatETA(left)+" left")
	}
	if len(notes) > 0 {
		parts = append(parts, p.paint("2", strings.Join(notes, " · ")))
	}
	fmt.Fprint(p.w, "\r\033[K"+strings.Join(parts, "  "))
}

// 結果の表の前に進捗の行を消し、出力に残さない。
func (p *progress) clear() {
	if p == nil {
		return
	}
	fmt.Fprint(p.w, "\r\033[K")
}

func (p *progress) paint(code, s string) string {
	if !p.color || s == "" {
		return s
	}
	return "\033[" + code + "m" + s + "\033[0m"
}

func formatETA(d time.Duration) string {
	switch {
	case d < time.Second:
		return "<1s"
	case d < time.Minute:
		return fmt.Sprintf("~%ds", int(d.Round(time.Second)/time.Second))
	}
	return fmt.Sprintf("~%dm%02ds", int(d/time.Minute), int(d%time.Minute/time.Second))
}
