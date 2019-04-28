# Deploy

How to install to an Ubuntu 18.04 LTS server:

## Packages

```
sudo apt-get -y update
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
sudo dpkg -i erlang-solutions_1.0_all.deb
sudo apt-get -y update
sudo apt-get -y install esl-erlang
sudo apt-get -y install elixir
sudo apt-get -y install git nginx
```

## Reverse proxy websocket

Edit NGINX conf:

    sudo nano /etc/nginx/sites-enabled/default

Before `server`:

```
upstream elixoids {
  server 127.0.0.1:8065 max_fails=5 fail_timeout=6s;
}
```

Server 'location':

```
    location / {

        allow all;

        # Proxy Headers
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_set_header X-Cluster-Client-Ip $remote_addr;

        # The Important Websocket Bits!
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_pass http://elixoids;
    }
```

Restart:

    sudo service nginx restart


Install and build game:

    cd /usr/share/games
    mkdir elixoids
    cd elixoids/
    git clone https://github.com/devstopfix/elixoids.git .
    mix deps.get
    mix compile

Run:

    mix run --no-halt
