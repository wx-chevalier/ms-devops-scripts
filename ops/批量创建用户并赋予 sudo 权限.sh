#!/bin/bash

username=yourname
password=yourpassword

if [ -n $username ]
then
   groupadd $username -g 10036
   useradd -m $username -g $username -u 10036
   echo "$password" | passwd --stdin $username
   echo "user $username  group $username is changed!"
else
   echo "use $username is fail"
fi

####add  sudo  power ####

echo "$username ALL = (root) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/$username
sudo chmod 0440 /etc/sudoers.d/$username