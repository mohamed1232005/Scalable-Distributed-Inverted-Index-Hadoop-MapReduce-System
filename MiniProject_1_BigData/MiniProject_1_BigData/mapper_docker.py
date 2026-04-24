#!/usr/bin/env python
import sys
import os
import string

def load_stopwords():
    stopwords = set()
    try:
        with open('stopwords.txt', 'r') as f:
            for line in f:
                word = line.strip().lower()
                if word:
                    stopwords.add(word)
    except:
        stopwords = {'the','is','at','which','a','an','and','or','but','in',
                     'on','for','to','of','with','as','by','from','it','its',
                     'this','that','was','are','were','be','been','have','has',
                     'had','do','does','did','will','would','could','should',
                     'not','no','so','if','up','out','then','there','when',
                     'where','who','how','all','each','more','some','other',
                     'i','you','he','she','we','they','me','him','her','us'}
    return stopwords

def main():
    stopwords = load_stopwords()
    filepath = os.environ.get('mapreduce_map_input_file',
                              os.environ.get('map_input_file', 'unknown.txt'))
    doc_name = os.path.basename(filepath)

    for line in sys.stdin:
        line = line.strip().lower()
        for ch in string.punctuation:
            line = line.replace(ch, ' ')
        words = line.split()
        for word in words:
            word = word.strip()
            if not word or word in stopwords:
                continue
            if not word.isalpha():
                continue
            print('%s\t%s' % (word, doc_name))

main()
