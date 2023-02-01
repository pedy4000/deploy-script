#!/usr/bin/env bash

set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)

usage() {
  cat << EOF # remove the space between << and EOF, this is due to web plugin issue
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] [-f] -p param_value arg1 [arg2...]
Script description here.
Available options:
-h, --help              Print this help and exit

--service_name          Name of service
--service-remote-name   Name of service's git remote, default 'origin'
--service-branch-name   Name of branch to deploy
--service-path          Path of the service located there, default '/home/docker'
--service-git-url       Git url of the service

--user                  User, default 'docker'

--password-path         Path of the password file
                        Sample:
                          SECRET_KEY secret
                          POSTGRES_PASSWORD secret
                          ELASTICSEARCH_PASSWORD secret
                          
EOF
  exit
}

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
  # script cleanup here
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

msg() {
  echo >&2 -e "${1-}"
}

die() {
  local msg=$1
  local code=${2-1} # default exit status 1
  msg "$msg"
  exit "$code"
}

parse_params() {
  # default values of variables set from params
  service_name=''
  service_remote_name='origin'
  service_branch_name=''
  service_path='/home/docker'
  service_git_url=''
  
  user="docker"
  
  passwrods=""

  while :; do
    case "${1-}" in
    -h | --help) usage ;;
    --service-name)
      service_name="${2-}"
      shift
      ;;
    --service-remote-name)
      service_remote_name="${2-}"
      shift
      ;;
    --service-branch-name)
      service_branch_name="${2-}"
      shift
      ;;
    --service-path)
      service_path="${2-}"
      shift
      ;;
    --service-git-url)
      service_git_url="${2-}"
      shift
      ;;
    --user)
      user="${2-}"
      shift
      ;;
    --password)
      password="${2-}"
      shift
      ;;
    ?*) die "Unknown option: $1" ;;
    *) break ;;
    esac
    [[ ! $# -eq 0 ]] && shift
  done
  echo "$@"
  args=("$@")

  # check required params and arguments
  [[ -z "${service_name-}" ]] && die "Missing required parameter: service_name"
  [[ -z "${service_remote_name-}" ]] && die "Missing required parameter: service_remote_name"
  [[ -z "${service_branch_name-}" ]] && die "Missing required parameter: service_branch_name"
  [[ -z "${service_path-}" ]] && die "Missing required parameter: service_path"
  [[ -z "${service_git_url-}" ]] && die "Missing required parameter: service_git_url"
  
  [[ -z "${user-}" ]] && die "Missing required parameter: user"
  
  [[ -z "${password-}" ]] && die "Missing required parameter: password"

  return 0
}

parse_params "$@"
setup_colors

# Update local repo on target server
if [ -d "$service_path/$service_name" ] 
then
    msg "Pulling service repo"
    cd $service_path/$service_name
    git checkout $service_branch_name
    git pull $service_remote_name $service_branch_name --force
else
    die "$service_path/$service_name doesn't exist"
fi

# Create secrets directory
if [ ! -d "$service_path/$service_name/secrests/$service_branch_name/" ] 
then
    msg "Creating secrets directory"
    mkdir --parents "$service_path/$service_name/secrets/$service_branch_name/"
    sudo chown -R $user:users "$service_path/$service_name/secrets/"
    sudo chmod -R 0750 "$service_path/$service_name/secrets/"
else
    msg "Secrets directory exist"
fi

# Copy all passwords from Jenkins Credentials
if [ -d "$password" ] 
then
  msg "Copy all passwords from Jenkins Credentials"
  cd $service_path/$service_name/secrets/$service_branch_name
  sudo awk '{filename=$1; print $2 > filename; close(filename)}' $password
else
  die "file $password not found" 

