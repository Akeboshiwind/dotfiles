# runit

A unit init scheme with service supervision

## Setup

Run the following from the dotfiles directory to link the files:

```bash
stow -v -t / runit
```

Then from the `bin` project run `runit-setup` to setup the correct folders for user services.

```bash
sudo runit-setup
```

To start up the runit service run the following:

```bash
sudo launchctl load /Library/LaunchDaemons/org.smarden.runit.plist
sudo launchctl start /Library/LaunchDaemons/org.smarden.runit.plist
```

## Adding services

Thanks to the `runit-setup` script the folder the folder `~/service` can be used to link services to.

So to add a service just link your service into that directory.

```bash``
ln -s ~/sv/<service-name>/ ~/service/<service-name>
```

## Possible Got'chas

### How to access launchctl's logs

```bash
tail -f /var/log/system.log
```

### The .plist file doesn't have the right permisssions

```bash
chown root:wheel /Library/LaunchDaemons/org.smarden.runit.plist
```

### My service logs aren't there

You probably need to create the folder for the logs to go into, or the folder has the wrong permissions.

e.g:
Controlplane is configured to send it's logs to `/var/log/controlplane/`

So if the directory doesn't exist, or is owned by root then the service won't be able to write the logs :P
