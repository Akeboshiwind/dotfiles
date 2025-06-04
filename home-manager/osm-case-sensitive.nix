{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.osm.caseSensitiveVolume;
in {
  options.osm.caseSensitiveVolume = {
    enable = mkEnableOption "Case-sensitive APFS volume for macOS";
    
    volumeName = mkOption {
      type = types.str;
      default = "CaseSensitiveRepos";
      description = "Name of the case-sensitive APFS volume to create";
    };
    
    mountPoint = mkOption {
      type = types.str;
      example = "${config.home.homeDirectory}/CaseSensitiveRepos";
      description = "Where to mount the case-sensitive volume";
    };
    
    referenceVolume = mkOption {
      type = types.str;
      default = "Nix Store";
      description = "Reference volume to determine which APFS container to use";
    };
    
    helperScriptPath = mkOption {
      type = types.str;
      default = "/Library/Scripts/mount-case-sensitive-volume.sh";
      description = "Path to the helper script for mounting the volume";
    };
    
    launchDaemonName = mkOption {
      type = types.str;
      default = "com.user.mountcasesensitive";
      description = "Name for the LaunchDaemon";
    };
    
    launchDaemonPath = mkOption {
      type = types.str;
      default = "/Library/LaunchDaemons/com.user.mountcasesensitive.plist";
      description = "Path to the LaunchDaemon plist file";
    };
  };
  
  config = mkIf cfg.enable {
    home.activation.ensureCaseSensitiveMountDir = hm.dag.entryBefore ["writeBoundary"] ''
      mkdir -p "${cfg.mountPoint}"
    '';
    
    home.activation.setupCaseSensitiveVolume = hm.dag.entryAfter ["writeBoundary"] (
      let
        helperScriptContent = ''
          #!/bin/bash

          VOLUME_NAME="${cfg.volumeName}"
          MOUNT_POINT="${cfg.mountPoint}"

          # Ensure the mount point exists
          mkdir -p "$MOUNT_POINT"

          # Check if already mounted
          if mount | grep -q "$MOUNT_POINT"; then
              echo "$VOLUME_NAME is already mounted"
              exit 0
          fi

          # Get the device
          VOLUME_DEVICE=$(diskutil info "$VOLUME_NAME" 2>/dev/null | grep "Device Node:" | awk '{print \$3}')

          if [ -z "$VOLUME_DEVICE" ]; then
              echo "Volume $VOLUME_NAME not found, attempting to create it"
              REFERENCE_CONTAINER=$(diskutil info "${cfg.referenceVolume}" 2>/dev/null | grep "Container:" | awk '{print \$3}')
              
              if [ -z "$REFERENCE_CONTAINER" ]; then
                  echo "Failed to detect reference container from ${cfg.referenceVolume}"
                  exit 1
              fi
              
              diskutil apfs addVolume "$REFERENCE_CONTAINER" APFSX "$VOLUME_NAME"
              VOLUME_DEVICE=$(diskutil info "$VOLUME_NAME" | grep "Device Node:" | awk '{print \$3}')
          fi

          # Mount the volume
          echo "Mounting $VOLUME_NAME to $MOUNT_POINT"
          mount -t apfs "$VOLUME_DEVICE" "$MOUNT_POINT"

          # Set permissions
          USER_ID=$(id -u ${builtins.getEnv "USER"})
          GROUP_ID=$(id -g ${builtins.getEnv "USER"})
          chown $USER_ID:$GROUP_ID "$MOUNT_POINT"

          echo "Volume $VOLUME_NAME mounted successfully at $MOUNT_POINT"
        '';
        
        launchDaemonContent = ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
              <key>Label</key>
              <string>${cfg.launchDaemonName}</string>
              <key>ProgramArguments</key>
              <array>
                  <string>${cfg.helperScriptPath}</string>
              </array>
              <key>RunAtLoad</key>
              <true/>
              <key>KeepAlive</key>
              <false/>
          </dict>
          </plist>
        '';
      in
      ''
        echo "Checking case-sensitive volume configuration..."
        
        NEEDS_UPDATE=0
        
        # Check if the helper script exists and has the correct content
        if [ ! -f "${cfg.helperScriptPath}" ] || ! echo '${helperScriptContent}' | cmp -s - "${cfg.helperScriptPath}"; then
          echo "Helper script needs to be created or updated"
          NEEDS_UPDATE=1
        fi
        
        # Check if the LaunchDaemon exists and has the correct content
        if [ ! -f "${cfg.launchDaemonPath}" ] || ! echo '${launchDaemonContent}' | cmp -s - "${cfg.launchDaemonPath}"; then
          echo "LaunchDaemon needs to be created or updated"
          NEEDS_UPDATE=1
        fi
        
        if [ "$NEEDS_UPDATE" = "1" ]; then
          echo "System files need updating. You'll be prompted for sudo password..."
          
          # Create the helper script
          echo '${helperScriptContent}' | $DRY_RUN_CMD sudo tee "${cfg.helperScriptPath}" > /dev/null
          $DRY_RUN_CMD sudo chmod +x "${cfg.helperScriptPath}"
          
          # Create the LaunchDaemon
          echo '${launchDaemonContent}' | $DRY_RUN_CMD sudo tee "${cfg.launchDaemonPath}" > /dev/null
          $DRY_RUN_CMD sudo chown root:wheel "${cfg.launchDaemonPath}"
          $DRY_RUN_CMD sudo chmod 644 "${cfg.launchDaemonPath}"
          
          # Reload the LaunchDaemon if it's already loaded
          if $DRY_RUN_CMD sudo launchctl list | grep -q "${cfg.launchDaemonName}"; then
            echo "Reloading LaunchDaemon..."
            $DRY_RUN_CMD sudo launchctl unload "${cfg.launchDaemonPath}"
            $DRY_RUN_CMD sudo launchctl load "${cfg.launchDaemonPath}"
          else
            echo "Loading LaunchDaemon..."
            $DRY_RUN_CMD sudo launchctl load "${cfg.launchDaemonPath}"
          fi
          
          echo "System configuration updated!"
        else
          echo "Case-sensitive volume configuration is up to date."
        fi
        
        # Check if the volume is mounted, if not try to mount it
        if ! mount | grep -q "${cfg.volumeName}"; then
          echo "Volume not mounted, attempting to mount..."
          # First try without sudo (if volume exists and permissions are right)
          if diskutil info "${cfg.volumeName}" &>/dev/null; then
            $DRY_RUN_CMD diskutil mount "${cfg.volumeName}" 2>/dev/null || \
            # If that fails, try to mount it through the helper script
            $DRY_RUN_CMD sudo "${cfg.helperScriptPath}"
          else
            # If volume doesn't exist, use the helper to create and mount it
            echo "Volume doesn't exist yet, creating with helper script (requires sudo)..."
            $DRY_RUN_CMD sudo "${cfg.helperScriptPath}"
          fi
        fi
      ''
    );
  };
}

