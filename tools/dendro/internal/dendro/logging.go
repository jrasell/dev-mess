package dendro

import (
	"fmt"
	"io"
	"os"
	"path/filepath"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// NewLogger creates a file-backed logger with optional console output.
// The returned function flushes and closes the log file.
func NewLogger(cacheDir, level string, console bool, consoleOutput io.Writer) (*zap.Logger, func(), error) {
	logLevel, err := zapcore.ParseLevel(level)
	if err != nil {
		return nil, nil, fmt.Errorf("invalid log level %q: %w", level, err)
	}
	logDir := filepath.Join(cacheDir, "depcheck")
	if err := os.MkdirAll(logDir, 0700); err != nil {
		return nil, nil, fmt.Errorf("create log directory %s: %w", logDir, err)
	}
	logPath := filepath.Join(logDir, "depcheck.log")
	file, err := os.OpenFile(logPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		return nil, nil, fmt.Errorf("open log file %s: %w", logPath, err)
	}
	encoder := zap.NewProductionEncoderConfig()
	encoder.EncodeTime = zapcore.ISO8601TimeEncoder
	cores := []zapcore.Core{zapcore.NewCore(zapcore.NewJSONEncoder(encoder), zapcore.AddSync(file), logLevel)}
	if console {
		cores = append(cores, zapcore.NewCore(zapcore.NewConsoleEncoder(encoder), zapcore.AddSync(consoleOutput), logLevel))
	}
	logger := zap.New(zapcore.NewTee(cores...), zap.AddCaller())
	logger.Info("logging initialized", zap.String("log_file", logPath))
	return logger, func() {
		_ = logger.Sync()
		_ = file.Close()
	}, nil
}
