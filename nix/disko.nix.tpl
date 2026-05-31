{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # The main system disk. The deployment provisioner detects the real
        # device over SSH at deploy time and substitutes __DISK_DEVICE__ in the
        # per-host generated copy of this file (never this source template).
        device = "__DISK_DEVICE__";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}