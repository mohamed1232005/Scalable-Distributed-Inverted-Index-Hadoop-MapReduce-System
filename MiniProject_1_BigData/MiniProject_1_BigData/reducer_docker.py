#!/usr/bin/env python
import sys
from collections import defaultdict

def emit(word, doc_counts):
    entries = ', '.join('%s:%d' % (d, c) for d, c in sorted(doc_counts.items()))
    print('%s --> %s' % (word, entries))

def main():
    current_word = None
    doc_counts = defaultdict(int)

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue
        parts = line.split('\t')
        if len(parts) != 2:
            continue
        word = parts[0]
        value = parts[1]

        if ':' in value:
            last = value.rfind(':')
            doc_name = value[:last]
            try:
                count = int(value[last+1:])
            except:
                count = 1
        else:
            doc_name = value
            count = 1

        if current_word and current_word != word:
            emit(current_word, doc_counts)
            doc_counts = defaultdict(int)

        current_word = word
        doc_counts[doc_name] += count

    if current_word:
        emit(current_word, doc_counts)

main()
