/*
 * Copyright 2024 Timo Stülten (pionira GmbH)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package de.sty;

import lombok.extern.slf4j.Slf4j;
import org.apache.commons.io.IOUtils;
import picocli.CommandLine;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Objects;

@Slf4j
@CommandLine.Command(name = "pwgen", mixinStandardHelpOptions = true)
public class PwGenCommand implements Runnable {

    @CommandLine.Parameters(description = "Number of words to combine.")
    int number;

    @CommandLine.Parameters(defaultValue = "3", description = "Generate this number of digits.")
    int numberOfDigits;

    @CommandLine.Parameters(defaultValue = "=/*-+", description = "Delimiters to use between Words")
    String delimiters;

    @CommandLine.Option(names = {"-U", "--wordsStartWithUppercase"}, description = "Set first character of each word to uppercase")
    boolean wordsStartWithUppercase;

    public List<String> readWordList(String filename) throws IOException {
        List<String> words;

        var in = PwGenCommand.class.getClassLoader().getResourceAsStream(filename);
        if (in == null) {
            System.err.println("Use default wordlist.");
            words = Wordlist.defaultWordList();
        } else {
            Objects.requireNonNull(in);
            words = new ArrayList<>();
            for (String word : IOUtils.readLines(in, StandardCharsets.UTF_8)) {
                word = word.trim();
                // replace blanks with CamelCase
                while (word.contains(" ")) {
                    int pos = word.indexOf(' ');
                    char uppercase = Character.toUpperCase(word.charAt(pos + 1));
                    word = word.substring(0, pos)
                            + uppercase
                            + word.substring(pos + 2);
                    word = word.trim();
                }
                words.add(word);
            }
        }

        return words;
    }

    public List<String> randomized(List<String> wordsRead, int size) {
        List<String> ret = new ArrayList<>();
        List<Integer> shuffle = new ArrayList<>();

        while (shuffle.size() < size) {
            Integer candidate = (int) (Math.random() * wordsRead.size());
            if (!shuffle.contains(candidate)) {
                shuffle.add(candidate);
                ret.add(wordsRead.get(candidate));
            }
        }

        return ret;
    }

    public List<String> delimiters() {
        List<String> ret = new ArrayList<>();
        for (int i = 0; i < delimiters.length(); i++) {
            ret.add("" + delimiters.charAt(i));
        }
        return ret;
    }

    public String generate(List<String> wordList, int number, List<String> delimiters, int numberOfDigits) {
        Objects.requireNonNull(wordList);
        if (number < 0 || number > wordList.size()) {
            throw new IllegalArgumentException("number must be > 0 and < " + wordList.size() + "! Actual: " + number);
        }
        Objects.requireNonNull(delimiters);

        String ret = "";
        List<Integer> shuffle = new ArrayList<>();
        boolean generateNumbers = numberOfDigits > 0;
        int numberPos = (int) (Math.random() * number);

        while (shuffle.size() < number) {
            Integer candidate = (int) (Math.random() * wordList.size());
            if (!shuffle.contains(candidate)) {
                shuffle.add(candidate);
            }
        }

        for (int i = 0; i < number; i++) {
            String word = wordList.get(shuffle.get(i));
            if (wordsStartWithUppercase) {
                word = Character.toUpperCase(word.charAt(0)) + word.substring(1);
            }
            ret += word;
            if (generateNumbers && numberPos == i) {
                ret += generateDigits(numberOfDigits);
            }
            if (i < number - 1) {
                int delim = (int) (Math.random() * delimiters.size());
                ret += delimiters.get(delim);
            }
        }

        return ret;
    }

    public String generateDigits(int numberOfDigits) {
        String ret = "";
        for (int j = 0; j < numberOfDigits; j++) {
            ret += (int) (Math.random() * 10);
        }
        return ret;
    }

    @Override
    public void run() {
        try {
            List<String> wordList = readWordList("wordlist_" + Locale.getDefault().getLanguage() + ".txt");
            String ret = generate(wordList, number, delimiters(), numberOfDigits);
            System.out.println(ret);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

}
