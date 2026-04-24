#!/usr/bin/env python3
"""
Reducer for Reverse Index MapReduce Job (when using Combiner)
Handles input in the format: word\tdocument_name:count
(as emitted by the combiner)

Input:  word\tdoc_name:count  (sorted by Hadoop shuffle phase)
Output: word --> doc1.txt:total_count, doc2.txt:total_count, ...
"""

import sys
from collections import defaultdict

def main():
    current_word = None
    doc_counts = defaultdict(int)

    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        parts = line.split("\t")
        if len(parts) != 2:
            continue

        word = parts[0]
        value = parts[1]  # format: "doc_name:count" or just "doc_name"

        # Parse doc_name and count (handles both combiner and non-combiner input)
        if ":" in value:
            last_colon = value.rfind(":")
            doc_name = value[:last_colon]
            count = int(value[last_colon+1:])
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

def emit(word, doc_counts):
    entries = ", ".join(
        f"{doc}:{count}"
        for doc, count in sorted(doc_counts.items())
    )
    print(f"{word} --> {entries}")

if __name__ == "__main__":
    main()
