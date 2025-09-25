package main

import (
	"bufio"
	"crypto/rand"
	"embed"
	"errors"
	"flag"
	"fmt"
	"log"
	"math/big"
	"os"
	"strconv"
	"strings"
)

//go:embed assets/*.txt
var wordFS embed.FS

// Config holds CLI arguments
type Config struct {
	Number                  int
	NumberOfDigits          int
	Delimiters              string
	WordsStartWithUppercase bool
	Lang                    string
	Verbose                 bool
}

//goland:noinspection GoUnhandledErrorResult
func usage() {
	fmt.Fprintf(os.Stderr, "Usage: pwgen-go [number=4] [numberOfDigits=3] [delimiters=\"=/*-+\"] [options]\n")
	fmt.Fprintf(os.Stderr, "Options:\n")
	fmt.Fprintf(os.Stderr, "  -U, --wordsStartWithUppercase   Set first character of each word to uppercase\n")
	fmt.Fprintf(os.Stderr, "  -L, --lang <code>               Language to use, e.g. 'de' or 'en'\n")
	fmt.Fprintf(os.Stderr, "  -v, --verbose                   Be verbose\n")
}

func parseArgs() (*Config, error) {
	cfg := &Config{
		Number:         4,
		NumberOfDigits: 3,
		Delimiters:     "=/*-+",
	}

	// Custom flag set to allow unknown args and positional handling
	fs := flag.NewFlagSet("pwgen-go", flag.ContinueOnError)
	fs.SetOutput(os.Stderr)
	fs.Usage = usage

	fs.BoolVar(&cfg.WordsStartWithUppercase, "U", false, "")
	fs.BoolVar(&cfg.WordsStartWithUppercase, "wordsStartWithUppercase", false, "")
	fs.StringVar(&cfg.Lang, "L", "", "")
	fs.StringVar(&cfg.Lang, "lang", "", "")
	fs.BoolVar(&cfg.Verbose, "v", false, "")
	fs.BoolVar(&cfg.Verbose, "verbose", false, "")

	// We can't directly define positionals with flag package, so parse known flags first
	// and then interpret remaining args as positionals in order.
	if err := fs.Parse(os.Args[1:]); err != nil {
		return nil, err
	}

	positionals := fs.Args()
	if len(positionals) > 0 {
		if n, err := strconv.Atoi(positionals[0]); err == nil {
			cfg.Number = n
		} else {
			return nil, fmt.Errorf("invalid number: %q", positionals[0])
		}
	}
	if len(positionals) > 1 {
		if n, err := strconv.Atoi(positionals[1]); err == nil {
			cfg.NumberOfDigits = n
		} else {
			return nil, fmt.Errorf("invalid numberOfDigits: %q", positionals[1])
		}
	}
	if len(positionals) > 2 {
		cfg.Delimiters = positionals[2]
	}

	// Detect default language from environment if not provided
	if cfg.Lang == "" {
		// Try LANG environment variable, format like en_US.UTF-8
		langEnv := os.Getenv("LANG")
		if langEnv != "" {
			// take part before '_' or '.'
			code := langEnv
			if idx := strings.IndexAny(code, "_."); idx >= 0 {
				code = code[:idx]
			}
			cfg.Lang = strings.ToLower(code)
		}
		if cfg.Lang == "" {
			cfg.Lang = "en"
		}
	}

	return cfg, nil
}

func readWordList(lang string, verbose bool) ([]string, error) {
	path := fmt.Sprintf("assets/wordlist_%s.txt", lang)
	file, err := wordFS.Open(path)
	if err != nil {
		if verbose {
			log.Printf("Cannot read embedded wordlist for language %s: %v", lang, err)
		}
		return nil, fmt.Errorf("cannot read wordlist for language %s", lang)
	}
	//goland:noinspection GoUnhandledErrorResult
	defer file.Close()

	scanner := bufio.NewScanner(file)
	words := make([]string, 0, 4096)
	for scanner.Scan() {
		w := strings.TrimSpace(scanner.Text())
		if w == "" {
			continue
		}
		for strings.Contains(w, " ") {
			pos := strings.IndexByte(w, ' ')
			if pos < 0 || pos+1 >= len(w) {
				break
			}
			upper := strings.ToUpper(string(w[pos+1]))
			w = strings.TrimSpace(w[:pos] + upper + w[pos+2:])
		}
		words = append(words, w)
	}
	if err := scanner.Err(); err != nil {
		return nil, err
	}
	if verbose {
		log.Printf("Loaded %d words from embedded %s", len(words), path)
	}
	return words, nil
}

// cryptoRandInt returns uniform random int in [0, n)
func cryptoRandInt(n int) (int, error) {
	if n <= 0 {
		return 0, errors.New("n must be > 0")
	}
	bn := big.NewInt(int64(n))
	r, err := rand.Int(rand.Reader, bn)
	if err != nil {
		return 0, err
	}
	return int(r.Int64()), nil
}

// cryptoRandDigit returns a random decimal digit as rune '0'..'9'
func cryptoRandDigit() (byte, error) {
	v, err := cryptoRandInt(10)
	if err != nil {
		return '0', err
	}
	return byte('0' + v), nil
}

// shuffleUniqueIndices returns k unique indices in [0, n)
func shuffleUniqueIndices(n, k int) ([]int, error) {
	if k < 0 || k > n {
		return nil, fmt.Errorf("k must be >= 0 and <= %d", n)
	}
	picked := make(map[int]struct{}, k)
	res := make([]int, 0, k)
	for len(res) < k {
		v, err := cryptoRandInt(n)
		if err != nil {
			return nil, err
		}
		if _, ok := picked[v]; !ok {
			picked[v] = struct{}{}
			res = append(res, v)
		}
	}
	return res, nil
}

func generateDigits(n int) (string, error) {
	if n <= 0 {
		return "", nil
	}
	b := make([]byte, n)
	for i := 0; i < n; i++ {
		d, err := cryptoRandDigit()
		if err != nil {
			return "", err
		}
		b[i] = d
	}
	return string(b), nil
}

func pickDelim(dels string) (string, error) {
	if dels == "" {
		return "", nil
	}
	idx, err := cryptoRandInt(len(dels))
	if err != nil {
		return "", err
	}
	return string(dels[idx]), nil
}

func generate(words []string, number int, delimiters string, numberOfDigits int, upperFirst bool) (string, error) {
	if words == nil {
		return "", errors.New("word list is nil")
	}
	if number < 0 || number > len(words) {
		return "", fmt.Errorf("number must be > 0 and <= %d! Actual: %d", len(words), number)
	}

	indices, err := shuffleUniqueIndices(len(words), number)
	if err != nil {
		return "", err
	}

	insertDigits := numberOfDigits > 0
	var numberPos int
	if number > 0 {
		numberPos, err = cryptoRandInt(number)
		if err != nil {
			return "", err
		}
	}

	var sb strings.Builder
	for i := 0; i < number; i++ {
		w := words[indices[i]]
		if upperFirst && len(w) > 0 {
			w = strings.ToUpper(w[:1]) + w[1:]
		}
		sb.WriteString(w)
		if insertDigits && i == numberPos {
			dig, err := generateDigits(numberOfDigits)
			if err != nil {
				return "", err
			}
			sb.WriteString(dig)
		}
		if i < number-1 {
			d, err := pickDelim(delimiters)
			if err != nil {
				return "", err
			}
			sb.WriteString(d)
		}
	}
	return sb.String(), nil
}

func main() {
	cfg, err := parseArgs()
	if err != nil {
		usage()
		_, _ = fmt.Fprintln(os.Stderr, "ERROR:", err)
		os.Exit(1)
	}

	words, err := readWordList(cfg.Lang, cfg.Verbose)
	if err != nil {
		_, _ = fmt.Fprintf(os.Stderr, "ERROR: Cannot read wordlist for language %s\n", cfg.Lang)
		os.Exit(1)
	}

	out, err := generate(words, cfg.Number, cfg.Delimiters, cfg.NumberOfDigits, cfg.WordsStartWithUppercase)
	if err != nil {
		_, _ = fmt.Fprintln(os.Stderr, "ERROR:", err)
		os.Exit(1)
	}

	fmt.Println(out)
}
