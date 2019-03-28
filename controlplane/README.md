# Controlplane

Controlplane allows you to automate some tasks in OSX

## Installation

For some reason it crashes regularly, for this reason a `runit` service has been created and can be enabled using the below:

```bash
mkdir /var/log/controlplane
sudo chown $(basename $HOME) /var/log/controlplane
ln -s ~/sv/controlplane/ ~/service/controlplane
```

As you can see from the above logs are gathered in `/var/log/controlplane`

## Usage

One usage for Controlplane is to automatically toggle bluetooth on lid close and open.
