Simple bind server to route all local queries back to 192.168.1.150
and block ads!

Needed Export
```bash
export EXTERNAL_IP=<ip>
```

To run 
```bash
docker-compose up -d
```

To reload the adblock lists run
```bash
docker exec $(docker ps -aqf "name=dockerbind")  /usr/sbin/update_adblock.sh
```