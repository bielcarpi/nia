package service

import (
	"sync"
	"time"
)

type windowEntry struct {
	started time.Time
	count   int
}

// WindowLimiter is an intentionally instance-local guardrail. Cloud Run's
// max-instance setting and the OpenAI project budget remain the distributed
// backstops; a distributed limiter can replace this interface if usage demands it.
type WindowLimiter struct {
	mu        sync.Mutex
	limit     int
	window    time.Duration
	now       func() time.Time
	entries   map[string]windowEntry
	nextSweep time.Time
}

func NewWindowLimiter(limit int, window time.Duration) *WindowLimiter {
	return &WindowLimiter{
		limit:   limit,
		window:  window,
		now:     time.Now,
		entries: make(map[string]windowEntry),
	}
}

func (l *WindowLimiter) Allow(key string) bool {
	if l == nil || l.limit <= 0 {
		return true
	}
	now := l.now()
	l.mu.Lock()
	defer l.mu.Unlock()
	if l.nextSweep.IsZero() || !now.Before(l.nextSweep) {
		for entryKey, entry := range l.entries {
			if !now.Before(entry.started.Add(l.window)) {
				delete(l.entries, entryKey)
			}
		}
		l.nextSweep = now.Add(l.window)
	}

	entry := l.entries[key]
	if entry.started.IsZero() || now.Sub(entry.started) >= l.window {
		l.entries[key] = windowEntry{started: now, count: 1}
		return true
	}
	if entry.count >= l.limit {
		return false
	}
	entry.count++
	l.entries[key] = entry
	return true
}
