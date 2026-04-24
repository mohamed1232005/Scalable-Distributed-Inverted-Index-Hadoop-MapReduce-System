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

### 🟦 Mapper

**Input:** Raw text line  
**Output:** `(word, document_name)`

Example:
```
whale    MobyDick.txt
sea      MobyDick.txt
```

---

### 🟨 Combiner (Bonus)

**Purpose:** Reduce shuffle size

```
(whale, MobyDick.txt) x 12 → (whale, MobyDick.txt:12)
```

---

### 🟥 Reducer

**Input:**
```
whale    MobyDick.txt:12, book2.txt:3
```

**Output:**
```
whale --> MobyDick.txt:12, book2.txt:3
```

---

## 🧮 Reverse Index Output Format

```
word --> document1.txt:frequency, document2.txt:frequency
```

Example:
```
aaron --> book1.txt:3, book2.txt:1
abating --> book1.txt:2, book3.txt:2
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
