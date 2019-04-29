# Deploy

How to install to an Ubuntu 18.04 LTS server:

## Erlang and Elixir

```bash
sudo apt-get -y update
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
sudo dpkg -i erlang-solutions_1.0_all.deb
sudo apt-get -y update
sudo apt-get -y install esl-erlang elixir
```

## Game

Create a user and add them the the games group:

```bash
export ELIXOIDS_HOME=/usr/local/games/elixoids
export ELIXOIDS_LOG=/var/log/elixoids

sudo apt-get -y install git htop

sudo adduser --disabled-password --ingroup games --gecos "" elixoids
sudo usermod -a -G games ubuntu

sudo mkdir $ELIXOIDS_HOME
sudo chown root:games $ELIXOIDS_HOME
sudo chmod g+rwx $ELIXOIDS_HOME

sudo mkdir $ELIXOIDS_LOG
sudo chown root:games $ELIXOIDS_LOG
sudo chmod g+rwx $ELIXOIDS_LOG

git clone https://github.com/devstopfix/elixoids.git $ELIXOIDS_HOME

cd $ELIXOIDS_HOME
mix local.hex --force
mix local.rebar --force
mix deps.get
mix compile
```

## NGINX Reverse Proxy

```bash
sudo apt-get -y install nginx
```

Edit NGINX conf:

    sudo nano /etc/nginx/sites-available/elixoids

with the contents of [elixoids.conf](elixoids.conf)

Enable the site and reload:

```bash
sudo ln -sfn /etc/nginx/sites-available/elixoids  /etc/nginx/sites-enabled/default
sudo nginx -t && sudo service nginx reload
```

## Run

Run as the elixoids user and allow logout of SSH session:

```bash
su - elixoids
nohup mix run --no-halt >> /var/log/elixoids/ zero.log &
```
