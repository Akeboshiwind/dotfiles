# Jupyter Clojure

A service to run a jupyter notebook with a clojure kernel installed.

This is run as a `runit` service and not in docker because I want to be able to run things on the actual machine (like machine learning stuff).

Once the service has started it should be available on http://localhost:8888/

The project files for the notebook are stored at `~/prog/notebook/`.

## Installation

This service can be enabled using the below:

```bash
mkdir /var/log/jupyter-clj
sudo chown $(basename $HOME) /var/log/jupyter-clj
ln -s ~/sv/jupyter-clj/ ~/service/jupyter-clj
cd ~/prog/notebook/
lein jupyter install-kernel
```

As you can see from the above logs are gathered in `/var/log/jupyter-clj`

## Usage

One usage for Controlplane is to automatically toggle bluetooth on lid close and open.
