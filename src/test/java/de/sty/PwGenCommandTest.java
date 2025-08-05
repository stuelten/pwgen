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
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import static org.junit.jupiter.api.Assertions.*;

@Slf4j
class PwGenCommandTest {

    @Test
    void readWordList() throws IOException {
        PwGenCommand pwGen = new PwGenCommand();
        List<String> wordsRead = pwGen.readWordList("wordlist_test.txt");

        assertTrue(wordsRead.contains("Orte"));
        assertTrue(wordsRead.contains("Sack"));
        assertTrue(wordsRead.contains("Üben"));
    }

    @Test
    void randomizedWords() throws IOException {
        PwGenCommand pwGen = new PwGenCommand();
        List<String> wordsRead = pwGen.readWordList("wordlist_test.txt");
        List<String> actual = pwGen.randomized(wordsRead, wordsRead.size());
        log.debug("Read     : {}", wordsRead);
        log.debug("Generated: {}", actual);

        assertEquals(wordsRead.size(), actual.size());
        for (String word : wordsRead) {
            assertTrue(actual.contains(word));
        }
        for (String word : actual) {
            assertTrue(wordsRead.contains(word));
        }
        boolean atLeastOneDifference = false;
        for (int i = 0; i < wordsRead.size(); i++) {
            if (!atLeastOneDifference) {
                atLeastOneDifference = !(actual.get(i).equals(wordsRead.get(i)));
            }
        }
        assertTrue(atLeastOneDifference);
    }

    @Test
    void generateDigits() {
        List<String> results = new ArrayList<>();
        PwGenCommand pwGen = new PwGenCommand();
        for (int i = 1; i < 11; i++) {
            String actual = pwGen.generateDigits(i);
            log.debug("Generated: {}", actual);
            assertEquals(i, actual.length());
            assertFalse(results.contains(actual));
            results.add(actual);
        }
    }

    @Test
    void testWordsStartWithUppercase() throws IOException {
        // Create command instance and set the flag
        PwGenCommand pwGen = new PwGenCommand();
        List<String> wordsRead = pwGen.readWordList("wordlist_test_lowercase.txt");

        for (int i = 0; i < wordsRead.size() * 5; i++) {
            pwGen.wordsStartWithUppercase = true;
            {
                String actual = pwGen.generate(wordsRead, 1, List.of("-"), 0);
                char firstChar = actual.charAt(0);
                char mustBeUppercase = Character.toUpperCase(firstChar);
                assertEquals(mustBeUppercase, firstChar, "Must start with uppercase: " + actual);
            }
            pwGen.wordsStartWithUppercase = false;
            {
                String actual = pwGen.generate(wordsRead, 1, List.of("-"), 0);
                char firstChar = actual.charAt(0);
                char mustBeLowercase = Character.toLowerCase(firstChar);
                assertEquals(mustBeLowercase, firstChar, "Must start with lowercase: " + actual);
            }
        }
    }

    @Test
    void replaceBlanksWithCamelCase() throws IOException {
        PwGenCommand pwGen = new PwGenCommand();
        List<String> wordsRead = pwGen.readWordList("wordlist_test_blanks.txt");
        for(String word : wordsRead) {
            assertFalse(word.contains(" "));
        }
        assertEquals("AutoBootCode", wordsRead.get(0));
        assertEquals("dachEuleFrau", wordsRead.get(1));
        assertEquals("Gast", wordsRead.get(2));
    }

}
