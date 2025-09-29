use clap::{ArgAction, Parser};
use locale_config::Locale;
use rand::seq::SliceRandom;
use rand::Rng;
use std::fs;
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(name = "pwgen", version, about = "Generate passphrases from word lists")] 
struct Args {
    /// Number of words to combine.
    #[arg(index = 1, default_value_t = 4)]
    number: usize,

    /// Generate this number of digits.
    #[arg(index = 2, default_value_t = 3)]
    number_of_digits: usize,

    /// Delimiters to use between words
    #[arg(index = 3, default_value = "=/*-+")]
    delimiters: String,

    /// Set first character of each word to uppercase
    #[arg(short = 'U', long = "wordsStartWithUppercase", action = ArgAction::SetTrue)]
    words_start_with_uppercase: bool,

    /// Language to use, e.g. 'de' or 'en'
    #[arg(short = 'L', long = "lang", default_value = "")]
    lang: String,

    /// be verbose.
    #[arg(short = 'v', long = "verbose", action = ArgAction::SetTrue)]
    verbose: bool,
}

fn main() {
    let args = Args::parse();

    let mut lang_to_use = args.lang.clone();
    if lang_to_use.is_empty() {
        // get system default language
        let locale = Locale::user_default();
        let language = locale.tags().next();
        if let Some((_, l)) = language {
            lang_to_use = l.as_ref().to_string();
        } else {
            lang_to_use = "en".to_string();
        }
        if args.verbose {
            eprintln!("Use default language: {}", lang_to_use);
        }
    }

    // Build list of candidate language tags with fallbacks (e.g., de-DE@EUR -> ["de-DE", "de"]).
    let candidates = candidate_langs(&lang_to_use);

    let mut last_err: Option<std::io::Error> = None;
    let mut loaded_list: Option<Vec<String>> = None;
    let mut tried: Vec<String> = Vec::new();

    for cand in &candidates {
        // Try local wordlists first
        let filename = format!("wordlists/wordlist_{}.txt", cand);
        tried.push(filename.clone());
        match read_word_list(&filename, args.verbose) {
            Ok(list) => { loaded_list = Some(list); break; },
            Err(e1) => {
                last_err = Some(e1);
                // Try /etc fallback
                let alt = format!("/etc/pwgen/wordlist_{}.txt", cand);
                tried.push(alt.clone());
                match read_word_list(&alt, args.verbose) {
                    Ok(list) => { loaded_list = Some(list); break; },
                    Err(e2) => { last_err = Some(e2); }
                }
            }
        }
    }

    match loaded_list {
        Some(word_list) => {
            if word_list.is_empty() {
                eprintln!("ERROR: Cannot read wordlist for language {} (empty list)", lang_to_use);
                std::process::exit(1);
            }
            let delimiters_vec = delimiters(&args.delimiters);
            match generate(
                &word_list,
                args.number,
                &delimiters_vec,
                args.number_of_digits,
                args.words_start_with_uppercase,
            ) {
                Ok(ret) => println!("{}", ret),
                Err(e) => {
                    eprintln!("ERROR: {}", e);
                    std::process::exit(1);
                }
            }
        }
        None => {
            if args.verbose {
                eprintln!("Tried the following paths (in order):");
                for t in tried { eprintln!("  {}", t); }
                if let Some(e) = last_err { eprintln!("Last error: {}", e); }
            }
            eprintln!("ERROR: Cannot read wordlist for language {} (with fallbacks)", lang_to_use);
            std::process::exit(1);
        }
    }
}

fn read_word_list(path: &str, verbose: bool) -> Result<Vec<String>, std::io::Error> {
    let mut full_path = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    full_path.push(path);
    let content = fs::read_to_string(&full_path).or_else(|e| {
        if verbose {
            eprintln!("Cannot read wordlist: {}", full_path.display());
        }
        Err(e)
    })?;

    let mut words = Vec::new();
    for mut line in content.lines().map(|l| l.trim().to_string()) {
        if line.is_empty() {
            continue;
        }
        // replace blanks with CamelCase
        while let Some(pos) = line.find(' ') {
            if pos + 1 >= line.len() {
                break;
            }
            let chars: Vec<char> = line.chars().collect();
            let upper = chars[pos + 1].to_uppercase().to_string();
            // new string: before space + uppercase(next char) + rest after next char
            let before = &line[..pos];
            let after = if pos + 2 <= line.len() { &line[pos + 2..] } else { "" };
            line = format!("{}{}{}", before, upper, after).trim().to_string();
        }
        words.push(line);
    }
    Ok(words)
}

fn candidate_langs(lang: &str) -> Vec<String> {
    // Normalize separators to '-'
    let mut base = lang.replace('_', "-");
    // Strip variant or encoding markers after '.' or '@'
    if let Some(idx) = base.find(['.', '@']) {
        base = base[..idx].to_string();
    }
    // Split into subtags
    let parts: Vec<&str> = base
        .split('-')
        .filter(|p| !p.is_empty())
        .collect();
    let mut out: Vec<String> = Vec::new();
    if parts.is_empty() {
        return out;
    }
    for i in (1..=parts.len()).rev() {
        out.push(parts[..i].join("-"));
    }
    out
}

fn delimiters(input: &str) -> Vec<String> {
    input.chars().map(|c| c.to_string()).collect()
}

fn generate(
    word_list: &Vec<String>,
    number: usize,
    delimiters: &Vec<String>,
    number_of_digits: usize,
    words_start_with_uppercase: bool,
) -> Result<String, String> {
    if number == 0 || number > word_list.len() {
        return Err(format!(
            "number must be > 0 and <= {}! Actual: {}",
            word_list.len(), number
        ));
    }

    // pick unique indices
    let mut indices: Vec<usize> = (0..word_list.len()).collect();
    let mut rng = rand::thread_rng();
    indices.shuffle(&mut rng);
    let chosen = &indices[..number];

    let generate_numbers = number_of_digits > 0;
    let number_pos = rng.gen_range(0..number);

    let mut ret = String::new();

    for (i, &idx) in chosen.iter().enumerate() {
        let mut word = word_list[idx].clone();
        if words_start_with_uppercase && !word.is_empty() {
            let mut chars = word.chars();
            if let Some(first) = chars.next() {
                word = first.to_uppercase().collect::<String>() + chars.as_str();
            }
        }
        ret.push_str(&word);
        if generate_numbers && number_pos == i {
            ret.push_str(&generate_digits(number_of_digits));
        }
        if i < number - 1 {
            let delim = rng.gen_range(0..delimiters.len());
            ret.push_str(&delimiters[delim]);
        }
    }

    Ok(ret)
}

fn generate_digits(number_of_digits: usize) -> String {
    let mut rng = rand::thread_rng();
    let mut s = String::new();
    for _ in 0..number_of_digits {
        s.push_str(&rng.gen_range(0..10).to_string());
    }
    s
}
