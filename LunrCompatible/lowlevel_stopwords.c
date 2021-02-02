#include <string.h>

// Low-level stopword matcher
// Only ASCII / English UTF-8
// You'll have a harder time pulling the same tricks with other languages

const char* stopwords[] = {"a", "able", "about", "across", "after", "all", "almost", "also", "am", "among", "an", "and", "any", "are", "as", "at", "be", "because", "been", "but", "by", "can", "cannot", "could", "dear", "did", "do", "does", "either", "else", "ever", "every", "for", "from", "get", "got", "had", "has", "have", "he", "her", "hers", "him", "his", "how", "however", "i", "if", "in", "into", "is", "it", "its", "just", "least", "let", "like", "likely", "may", "me", "might", "most", "must", "my", "neither", "no", "nor", "not", "of", "off", "often", "on", "only", "or", "other", "our", "own", "rather", "said", "say", "says", "she", "should", "since", "so", "some", "than", "that", "the", "their", "them", "then", "there", "these", "they", "this", "tis", "to", "too", "twas", "us", "wants", "was", "we", "were", "what", "when", "where", "which", "while", "who", "whom", "why", "will", "with", "would", "yet", "you", "your"};
const int wordcount = 119;

int is_word_allowed(char* word) {
	// There's no words longer than 7 in the list above
	// Exit early if word longer than 7
	if (strnlen(word, 8) == 8) return 1;

	for (int i = 0; i < wordcount; i++) {
		if (strncasecmp(word, stopwords[i], 8) == 0) return 0;
	}

	return 1;
}
