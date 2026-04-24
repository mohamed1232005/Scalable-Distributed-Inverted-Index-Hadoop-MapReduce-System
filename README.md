# 📚 The Digital Librarian  
## Distributed Reverse Indexing using HDFS & MapReduce

---

## 🧾 Project Overview

This project implements a **Distributed Reverse Index** using **Apache Hadoop (HDFS + MapReduce)** on a **Docker-based multi-node cluster**. The system processes a corpus of public-domain books and constructs an **inverted index** mapping each word to the documents it appears in along with its frequency.

A reverse index is a foundational data structure used in **search engines**, enabling fast keyword-based retrieval across large datasets.

---

## 🎯 Objectives

- Design a **distributed storage system** using HDFS
- Implement **MapReduce jobs** using Hadoop Streaming (Python)
- Build a **Reverse Index** for large-scale text processing
- Apply **data preprocessing techniques** (normalization, stop-word removal)
- Evaluate **horizontal scalability** using multi-node cluster execution
- Analyze performance using **Speedup (S)**

---

## 🏗️ Architecture Overview

| Component | Description |
|----------|------------|
| HDFS | Distributed storage for input dataset |
| Mapper | Tokenizes and emits (word, document) |
| Combiner | Performs local aggregation (optimization) |
| Reducer | Aggregates final word-document frequencies |
| YARN | Resource management and job scheduling |
| Docker Cluster | Simulates multi-node Hadoop environment |

---

## 📁 Project Structure

```
MiniProject_1_BigData/
│
├── mapper_docker.py          # Mapper script
├── combiner_docker.py        # Combiner script (bonus optimization)
├── reducer_docker.py         # Reducer script
├── reducer_with_combiner.py  # Alternative reducer
│
├── stopwords.txt             # Stop-word list (100+ words)
│
├── docker-compose.yml        # Hadoop multi-node cluster setup
├── docker_run.sh             # Script to run jobs and measure time
├── hadoop.env                # Hadoop environment configuration
│
├── README.md                 # Project documentation
└── LICENSE
```

---

## 📚 Dataset

- Source: **Project Gutenberg – Top Downloaded Books**
- Dataset Link: https://www.gutenberg.org/browse/scores/top
- Number of books used: **20**
- Format: Plain Text (UTF-8)
- Total size: ~19 MB

### 🔗 Dataset Selection Justification

The dataset was selected from the official **Project Gutenberg "Top 100 EBooks" page**, which lists the most frequently downloaded public-domain books.

- This page dynamically ranks books based on **download frequency over time (daily, weekly, monthly)** :contentReference[oaicite:0]{index=0}  
- It provides a curated list of **popular, high-quality, and diverse literary works**  
- Ensures dataset relevance and avoids arbitrary book selection  

Example books from this page include:
- *Frankenstein* — Mary Shelley  
- *Moby Dick* — Herman Melville  
- *The City of God* — St. Augustine :contentReference[oaicite:1]{index=1}  

---

### 📖 About Project Gutenberg

**Project Gutenberg** is the world's oldest digital library, founded in 1971, offering **free access to tens of thousands of public-domain books** in multiple formats :contentReference[oaicite:2]{index=2}.

Key characteristics:
- ✔ Over **75,000+ free eBooks**
- ✔ Primarily public-domain literature
- ✔ Available in plain text, HTML, EPUB, etc.
- ✔ Open access and freely distributable

---

### 📂 Dataset Storage in HDFS

All selected books were uploaded to:

```
/user/student/library/
```

Verification:

```bash
hdfs dfs -ls /user/student/library/
```

---

### 📊 Dataset Summary

| Metric | Value |
|------|------|
| Number of Books | 20 |
| Total Size | ~19 MB |
| Largest File | ~5.4 MB |
| Format | Plain Text |
| Encoding | UTF-8 |
| Source | Project Gutenberg |

---

### 🧠 Why This Dataset is Suitable

| Reason | Explanation |
|------|------------|
| Real-world data | Books simulate large text corpora used in search engines |
| Scalable | Can easily scale to hundreds or thousands of books |
| Clean format | Plain text simplifies preprocessing |
| Public domain | No copyright restrictions |
| Diversity | Covers multiple authors, genres, and writing styles |

---

### ⚠️ Notes

- Only **plain text versions** of books were used (no HTML or EPUB)
- Files were cleaned to remove metadata headers when necessary
- Dataset size (~19 MB) is small for Hadoop, but sufficient for demonstrating distributed processing concepts


---

## ⚙️ Preprocessing Pipeline

### 1. Normalization
- Convert all text to lowercase
- Remove punctuation

```python
line = line.lower()
line = line.translate(str.maketrans('', '', string.punctuation))
```

---

### 2. Stop-word Removal

- Uses `stopwords.txt`
- Loaded into memory as a Python `set`

```python
if word not in stopwords:
    emit(word, filename)
```

---

### 3. Alphabetic Filtering

```python
if word.isalpha():
```

---

## 🔁 MapReduce Workflow

The Reverse Index is built using the standard Hadoop MapReduce pipeline:

```
Input Text Files → Mapper → Combiner → Shuffle & Sort → Reducer → Reverse Index Output
```

---

### 🟦 Mapper Phase

The Mapper reads each input book line by line from HDFS, cleans the text, removes stop words, and emits each valid word with the document name where it appeared.

| Item | Description |
|---|---|
| Input | Raw text line from a book file |
| Processing | Lowercase text, remove punctuation, split into tokens, remove stop words, keep alphabetic words only |
| Output Key | `word` |
| Output Value | `document_name` |
| Output Pair | `(word, document_name)` |

#### Mapper Input Example

```text
Call me Ishmael. Some years ago...
```

#### Mapper Output Example

```text
call    MobyDick.txt
ishmael MobyDick.txt
years   MobyDick.txt
ago     MobyDick.txt
```

---

### 🟨 Combiner Phase

The Combiner is an optional local optimization that runs after the Mapper and before the Shuffle phase. It aggregates repeated `(word, document)` pairs locally on each mapper node to reduce the amount of intermediate data sent across the network.

| Item | Description |
|---|---|
| Input | Mapper output pairs |
| Processing | Count repeated occurrences of the same word within the same document locally |
| Output Key | `word` |
| Output Value | `document_name:local_count` |
| Output Pair | `(word, document_name:local_count)` |

#### Combiner Input Example

```text
whale   MobyDick.txt
whale   MobyDick.txt
whale   MobyDick.txt
sea     MobyDick.txt
```

#### Combiner Output Example

```text
whale   MobyDick.txt:3
sea     MobyDick.txt:1
```

---

### 🟪 Shuffle and Sort Phase

The Shuffle and Sort phase is handled automatically by Hadoop. It transfers intermediate mapper or combiner output across the cluster, groups records by key, and ensures that all values belonging to the same word are sent to the same reducer.

| Item | Description |
|---|---|
| Input | Combiner output if combiner is enabled; otherwise raw Mapper output |
| Processing | Partition by key, transfer data across nodes, sort keys alphabetically, group all values for the same word |
| Output Key | `word` |
| Output Value | List of document-frequency values |
| Output Group | `(word, [document_name:count, document_name:count, ...])` |

#### Shuffle Input Example

```text
whale   MobyDick.txt:3
whale   MobyDick.txt:5
whale   Book2.txt:2
sea     MobyDick.txt:1
sea     Book3.txt:4
```

#### Shuffle Output Example

```text
whale   [MobyDick.txt:3, MobyDick.txt:5, Book2.txt:2]
sea     [MobyDick.txt:1, Book3.txt:4]
```

#### Why Shuffle Matters

The Shuffle phase is one of the most expensive stages in MapReduce because it requires network communication between nodes. Using the Combiner reduces the number of records sent through Shuffle, which improves performance.

---

### 🟥 Reducer Phase

The Reducer receives one word at a time with all document-frequency values associated with that word. It merges counts for the same document and produces the final reverse index entry.

| Item | Description |
|---|---|
| Input | Grouped key-value pairs from Shuffle and Sort |
| Processing | Sum counts per document for each word and format the final index entry |
| Output Key | `word` |
| Output Value | `document1.txt:frequency, document2.txt:frequency, ...` |
| Final Output | `word --> document1.txt:frequency, document2.txt:frequency, ...` |

#### Reducer Input Example

```text
whale   [MobyDick.txt:3, MobyDick.txt:5, Book2.txt:2]
```

#### Reducer Output Example

```text
whale --> MobyDick.txt:8, Book2.txt:2
```

---

### ✅ Final Reverse Index Output Format

```text
word --> document1.txt:frequency, document2.txt:frequency, document3.txt:frequency
```

#### Final Output Example

```text
aaron --> Chambers'sTwentiethCentury.txt:3, TheBlueCastle_anovel.txt:1, TheCompleteWorksofWilliamShakespeare.txt:98
abating --> Chambers'sTwentiethCentury.txt:2, Dracula.txt:2, MobyDick.txt:2
abdomen --> Chambers'sTwentiethCentury.txt:6
```

---

## 🚀 Running the Project

### 1. Start Hadoop Cluster

```bash
docker-compose up -d
```

---

### 2. Upload Dataset to HDFS

```bash
hdfs dfs -mkdir -p /user/student/library
hdfs dfs -put *.txt /user/student/library/
```

---

### 3. Run MapReduce Job

```bash
bash docker_run.sh
```

---

### 4. View Output

```bash
hdfs dfs -cat /user/hadoop/output/part-00000
```

---

## 📊 Performance Analysis

### Execution Time Results

| Run | Configuration | Reducers | Time (T) | Speedup S = T₁/Tₙ |
|-----|--------------|----------|---------|-------------------|
| 1 | 1 Node | 1 | 404 s | 1.00 |
| 2 | 2 Nodes | 2 | 359 s | 1.13 |
| 3 | 3 Nodes | 3 | 354 s | 1.14 |
| 4 | 5 Nodes | 5 | 350 s | 1.15 |

---

## 📈 Speedup Formula

```
S(n) = T₁ / Tₙ
```

Where:
- `T₁` = execution time with 1 node
- `Tₙ` = execution time with n nodes

---

## ⚠️ Scalability Observations

- Achieved **positive but sub-linear speedup**
- Main limiting factors:

| Factor | Explanation |
|-------|------------|
| Amdahl’s Law | Sequential parts limit scalability |
| Single CPU | All containers share 1 core |
| Docker Overhead | Network and container cost |
| Shuffle Overhead | Increases with reducers |

---

## 🔍 Bottleneck Analysis

| Bottleneck | Evidence | Recommendation |
|-----------|---------|---------------|
| CPU limitation | nproc = 1 | Use multi-core machine |
| Disk spill | 389,468 records | Increase sort buffer |
| GC overhead | 43,840 ms | Increase JVM heap |
| Shuffle growth | 23 → 60 maps | Tune reducers |
| Killed tasks | 6 per run | Increase memory |

---

## ⚡ Combiner Optimization

### Impact:

| Metric | Before | After | Improvement |
|-------|--------|-------|-------------|
| Records | 1,609,587 | 194,734 | ↓ 87.9% |
| Shuffle Size | ~53 MB | ~7 MB | ↓ 7.6× |

---

## 🧠 Reducer Count Effect

| Reducers | Shuffle Maps | Time |
|----------|-------------|------|
| 1 | 23 | 404 s |
| 2 | 40 | 359 s |
| 3 | 60 | 354 s |
| 5 | ~100 | 350 s |

---

## 🏗️ HDFS Design Justification

| Feature | Benefit |
|--------|--------|
| Block Storage (128MB) | Parallel map tasks |
| Replication (factor=2) | Fault tolerance |
| Data Locality | Reduced network cost |

---

## 📌 Key Results

- Indexed **67,210 unique words**
- Generated **6.4 MB reverse index**
- Demonstrated **distributed processing**
- Achieved **horizontal scalability**

---

## 🏁 Conclusion

This project successfully demonstrates how distributed systems can efficiently process large-scale text data. While scalability is limited by hardware constraints, the system design aligns with real-world search engine indexing pipelines.

---

## 📜 License

This project is licensed under the MIT License.

---

## 👨‍💻 Authors

- Mohamed Ehab Yousri  
- Yousef Selim  

---

## 📎 Notes

- Ensure consistent file naming (`mapper.py` vs `mapper_docker.py`)
- Verify cluster configuration vs reported nodes
- Always include performance report in submission ZIP

---

## ⭐ Final Thoughts

This project reflects a complete **Data Science Lifecycle**:
- Data Collection
- Data Cleaning
- Distributed Processing
- Performance Evaluation

A strong foundation for understanding **Big Data Systems** and **Search Engine Architecture**.

---
