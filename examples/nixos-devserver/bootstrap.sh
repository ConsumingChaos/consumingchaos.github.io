#!/usr/bin/env zsh
set -euo pipefail

GITHUB_TOKEN="<token>"

if [ $# -ne 3 ]; then
	echo "USAGE: bootstrap.sh <IP_ADDRESS> <HOSTNAME> <NIX_IMAGE>"
	exit 1
fi

IP_ADDRESS=$1
HOSTNAME=$2
NIX_IMAGE=$3

ssh root@${IP_ADDRESS} <<-EOF
	set -euo pipefail

	# Check UEFI
	echo "Checking UEFI..."
	efivar -l >/dev/null 2>&1
	if [[ \$? -ne 0 ]]; then
		echo "ERROR: UEFI not detected!"
		exit 1
	fi
	echo "UEFI detected!"

	# Check NVME
	echo "Checking NVME..."
	stat /dev/nvme0n1 >/dev/null 2>&1
	if [[ \$? -ne 0 ]]; then
		echo "ERROR: NVME not detected!"
		exit 1
	fi
	echo "NVME detected!"

	# Partition
	echo "Partitioning..."
	parted /dev/nvme0n1 --script -- mklabel gpt
	parted /dev/nvme0n1 --script -- mkpart primary 512MB -8GB
	parted /dev/nvme0n1 --script -- mkpart primary linux-swap -8GB 100%
	parted /dev/nvme0n1 --script -- mkpart ESP fat32 1MB 512MB
	parted /dev/nvme0n1 --script -- set 3 esp on
	echo "Partitioned!"

	# Format
	echo "Formatting..."
	mkfs.ext4 -L nixos /dev/nvme0n1p1
	mkswap -L swap /dev/nvme0n1p2
	mkfs.fat -F 32 -n boot /dev/nvme0n1p3
	echo "Formatted!"

	# Mount
	echo "Mounting..."
	mkdir -p /mnt
	mount /dev/nvme0n1p1 /mnt
	mkdir -p /mnt/boot
	mount /dev/nvme0n1p3 /mnt/boot
	swapon /dev/nvme0n1p2
	echo "Mounted!"

	# Install
	echo "Installing..."
	export NIX_CONFIG="$(printf "access-tokens = github.com=${GITHUB_TOKEN}\nexperimental-features = nix-command flakes")"
	nixos-generate-config --root /mnt
	cat <<EOF2 > /mnt/etc/nixos/flake.nix
	{
	  description = "${HOSTNAME} (${NIX_IMAGE})";

	  inputs = {
	    consumingchaos.url = github:ConsumingChaos/consumingchaos.github.io?dir=examples/nixos-devserver;

	    nixpkgs.follows = "consumingchaos/nixpkgs";
	  };

	  outputs = { self, nixpkgs, consumingchaos }: {
	    nixosConfigurations."${HOSTNAME}" = nixpkgs.lib.nixosSystem {
	      system = "x86_64-linux";
	      modules = [
	        consumingchaos.nixosModules."x86_64-linux".${NIX_IMAGE}
	        ./configuration.nix
			./secrets.nix
	      ];
	    };
	  };
	}
	EOF2
	cat <<EOF2 > /mnt/etc/nixos/configuration.nix
	{ config, pkgs, ... }:
	{
	  imports =
	    [
	      # Include the results of the hardware scan.
	      ./hardware-configuration.nix
	    ];

	  # Use the systemd-boot EFI boot loader.
	  boot.loader.systemd-boot.enable = true;
	  boot.loader.efi.canTouchEfiVariables = true;

	  # Hostname
	  networking.hostName = "${HOSTNAME}";

	  # Nix Settings
	  nix.settings = {
	    access-tokens = [ "github.com=${GITHUB_TOKEN}" ];
	    experimental-features = [ "nix-command" "flakes" ];
	  };

	  system.stateVersion = "22.11";
	}
	EOF2
	cat <<EOF2 > /mnt/etc/nixos/secrets.nix
	{ config, pkgs, ... }:
	{
	  config = {
	    consumingchaos = { };
	  };
	}
	EOF2
	nixos-install --no-root-password --flake /mnt/etc/nixos#${HOSTNAME}
	echo "Installed"

	# Shutdown
	echo "Shutting down..."
	shutdown now
EOF
