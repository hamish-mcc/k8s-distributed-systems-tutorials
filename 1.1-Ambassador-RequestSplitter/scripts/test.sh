count=20
for i in $(seq $count); do
    curl http://127.0.0.1:8080 -s >> test-output.txt
done