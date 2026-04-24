#!/bin/bash
# =============================================================
# docker_run.sh — Run MapReduce job on Docker Hadoop cluster
# Usage:
#   bash docker_run.sh 1   → 1 node  (namenode + datanode1)
#   bash docker_run.sh 2   → 2 nodes (namenode + datanode1 + datanode2)
#   bash docker_run.sh 3   → 3 nodes (all nodes)
# =============================================================

NODES=${1:-1}
BOOKS_DIR=~/Desktop/Books
SCRIPTS_DIR=~/Desktop/Books

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} Docker Hadoop Cluster — $NODES Node(s)    ${NC}"
echo -e "${GREEN}============================================${NC}"

# Step 1: Wait for namenode to be ready
echo -e "${YELLOW}Waiting for namenode to be ready...${NC}"
sleep 15

# Step 2: Create HDFS directory inside namenode container
echo -e "${YELLOW}Creating HDFS library directory...${NC}"
docker exec namenode hdfs dfs -mkdir -p /user/student/library 2>/dev/null || true

# Step 3: Copy books into namenode container then upload to HDFS
echo -e "${YELLOW}Uploading books to HDFS inside Docker...${NC}"
for f in "$BOOKS_DIR"/*.txt; do
    fname=$(basename "$f")
    echo "  Uploading: $fname"
    docker cp "$f" namenode:/tmp/"$fname"
    docker exec namenode hdfs dfs -put -f /tmp/"$fname" /user/student/library/
done

# Step 4: Copy scripts into namenode
echo -e "${YELLOW}Copying MapReduce scripts...${NC}"
docker cp "$SCRIPTS_DIR/mapper.py"                namenode:/tmp/
docker cp "$SCRIPTS_DIR/reducer_with_combiner.py" namenode:/tmp/reducer.py
docker cp "$SCRIPTS_DIR/combiner.py"              namenode:/tmp/
docker cp "$SCRIPTS_DIR/stopwords.txt"            namenode:/tmp/

# Step 5: Install python3 in namenode if needed
echo -e "${YELLOW}Checking Python3 in container...${NC}"
docker exec namenode bash -c "which python3 || yum install -y python3 || apt-get install -y python3"

# Step 6: Remove old output
docker exec namenode hdfs dfs -rm -r /user/student/docker_output 2>/dev/null || true

# Step 7: Record start time and run job
echo -e "${YELLOW}Starting MapReduce job with $NODES node(s)...${NC}"
START=$(date +%s)

STREAMING_JAR=$(docker exec namenode find /opt/hadoop -name "hadoop-streaming*.jar" 2>/dev/null | head -1)

docker exec namenode bash -c "
    hadoop jar $STREAMING_JAR \
    -D mapreduce.job.name='ReverseIndex_Docker_${NODES}nodes' \
    -D mapreduce.job.reduces=$NODES \
    -files /tmp/mapper.py,/tmp/reducer.py,/tmp/combiner.py,/tmp/stopwords.txt \
    -mapper 'python3 /tmp/mapper.py' \
    -combiner 'python3 /tmp/combiner.py' \
    -reducer 'python3 /tmp/reducer.py' \
    -input /user/student/library \
    -output /user/student/docker_output
"

END=$(date +%s)
ELAPSED=$((END - START))

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN} Job Complete!${NC}"
echo -e "${GREEN} Nodes: $NODES${NC}"
echo -e "${GREEN} Time:  $ELAPSED seconds${NC}"
echo -e "${GREEN}============================================${NC}"

# Step 8: Show sample output
echo -e "${YELLOW}Sample output:${NC}"
docker exec namenode hdfs dfs -cat /user/student/docker_output/part-* 2>/dev/null | head -20

# Step 9: Save timing
echo "DOCKER >> Nodes=$NODES, Time=${ELAPSED}s, Date=$(date)" >> ~/Desktop/Books/docker_timing_log.txt
echo -e "${GREEN}Timing saved to ~/Desktop/Books/docker_timing_log.txt${NC}"
