#!/bin/bash

if [ ! -f domjudge-key ]; then
    ssh-keygen -f domjudge-key
fi

terraform apply

ansible-galaxy install geerlingguy.mysql

ansible-playbook -i hosts domjudge.yml