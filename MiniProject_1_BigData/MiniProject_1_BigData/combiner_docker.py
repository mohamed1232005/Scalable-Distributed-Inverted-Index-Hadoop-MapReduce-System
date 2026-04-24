#!/usr/bin/env python
import sys
from collections import defaultdict

def main():
    word_doc_counts = defaultdict(lambda: defaultdict(int))

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        parts = line.split('\t')
        if len(parts) != 2:
            continue
        word, doc_name = parts[0], parts[1]
        word_doc_counts[word][doc_name] += 1

    for word in sorted(word_doc_counts.keys()):
        for doc_name, count in word_doc_counts[word].items():
            print('%s\t%s:%d' % (word, doc_name, count))

main()
