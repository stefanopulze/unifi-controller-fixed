#!/bin/bash

unifi_version=$1
unifi_temp_folder=$2

echo "Unifi controller fixed script"

if [ -z "$unifi_version" ]; then
	echo "Please specify unifi controller version as first param"
	exit 1
fi

if [ -z "$unifi_temp_folder" ]; then
	unifi_temp_folder=$(mktemp -d -t unifi-XXXX)
fi

if [ ! -d $unifi_temp_folder ]; then
	mkdir -p $unifi_temp_folder
	if [ $? -ne 0 ]; then
		exit 1
	fi
fi

# vars
unifi_original_deb_file=$unifi_temp_folder/unifi.deb

echo ""
echo "Unifi controller: ${unifi_version}"
echo "Temp directory: ${unifi_temp_folder}"
echo ""
# TODO check valid version

# Download unifi controller
if [ ! -f $unifi_original_deb_file ]; then
	unifi_download_url="https://dl.ui.com/unifi/${unifi_version}/unifi_sysvinit_all.deb"
	echo "Downloading Unifi Controller ${unifi_version} from $unifi_download_url"
	curl --progress-bar -o $unifi_original_deb_file  $unifi_download_url
	if [ $? -ne 0 ]; then
		echo "Error download unifi controller file"
		echo "Please check:"
		echo "- unifi controller version from official site \"https://www.ui.com/download\""
		echo "- check folder permission"
		exit 1
	fi
	echo "Download completed"
else
	echo "Unifi controller file ${unifi_original_deb_file} already exists"
fi

# Extracting deb file
unifi_fixed_directory=$unifi_temp_folder/fixed
rm -rf $unifi_fixed_directory
echo "Extracting deb file..."
dpkg-deb -R $unifi_original_deb_file $unifi_fixed_directory

echo "Backup original control file"
unifi_control_file=$unifi_fixed_directory/DEBIAN/control
mv $unifi_control_file $unifi_control_file-original

echo "Remove mongodb dependencies"
sed '/^ mongodb/d' $unifi_control_file-original >> $unifi_control_file

# Repacking
echo "Repacking deb"
unifi_fixed_deb_file=$unifi_temp_folder/unifi-fixed.deb
dpkg-deb -b $unifi_fixed_directory $unifi_fixed_deb_file

echo "Cleaning resources"
rm -rf $unifi_original_deb_file
rm -rf $unifi_fixed_directory

echo "Repack complete"
echo ""
echo "🍺 You can now install Unifi controller without mongodb dependencies"
echo "with the command: \"apt install .${unifi_fixed_deb_file}\""
echo ""

