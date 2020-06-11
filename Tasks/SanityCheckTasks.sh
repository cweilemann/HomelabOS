#!/usr/bin/env bash

# Checks to make sure the current environment is setup correctly
Task::sanity_check(){
  if [[ -v "already_ran[${FUNCNAME[0]}]" ]] ;  then exit 0; fi
  already_ran[${FUNCNAME[0]}]=1

  Task::check_vault_pass
  Task::check_ssh_keys
  Task::check_ssh_with_keys
  Task::check_for_git

  colorize green "Sanity checks passed"
}

Task::check_for_git(){
  git --version 2>&1 >/dev/null # improvement by tripleee
  GIT_IS_AVAILABLE=$?
  if ! [ $GIT_IS_AVAILABLE -eq 0 ]; then
    colorize red "You need to install Git"
  fi
}

Task::check_ssh_with_keys(){
  IP=$(Task::run_docker yq r "settings/config.yml" "homelab_ip" | tr -d '[:space:]')
  USERNAME=$(Task::run_docker yq r "settings/config.yml" "homelab_ssh_user" | tr -d '[:space:]')
  Task::run_docker ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$USERNAME@$IP" exit 2>&1
  if ! [ $? -eq 0 ]; then
    colorize red "HomelabOS is unable to ssh to your server using the information in your config.yml: $USERNAME at $IP, "
    colorize red "and your $HOME/.ssh/id_rsa keypair to SSH into your server"
  fi
}

Task::check_vault_pass(){
  if [[ -v "already_ran[${FUNCNAME[0]}]" ]] ;  then exit 0; fi
  already_ran[${FUNCNAME[0]}]=1

  if [ ! -f "$HOME/.homelabos_vault_pass" ]; then
    echo "Oops, I cannot find your vault password in $HOME/.homelabos_vault_pass"
    echo "This is unusual, but could be caused by the user being changed during setup."
    colorize red "FIX: Create the file in the right place.  Then file a bug report."
    exit 1
  fi
}

Task::check_ssh_keys() {
  if ! [ -f "$HOME/.ssh/id_rsa" -a -f "$HOME/.ssh/id_rsa.pub" -a -f "$HOME/.homelabos_vault_pass" ]; then
    echo "You have no SSH keys in your home directory: $HOME"
    echo "Please generate a set of keys using the command:"
    echo "   ssh-keygen -t rsa"
    echo "or copy your id_rsa and id_rsa.pub keys to $HOME/.ssh/"
    echo "Then retry the operation"
    read -p "Press ctrl-c and fix your ssh keys"
    exit 1
  fi
}

# It would be nice to verify passwordless ssh to the server works.
