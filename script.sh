for ARGUMENT in "$@"
do
   KEY=$(echo $ARGUMENT | cut -f1 -d=)

   KEY_LENGTH=${#KEY}
   VALUE="${ARGUMENT:$KEY_LENGTH+1}"

   export "$KEY"="$VALUE"
done

if [ -d "/home/dockeru/$SERVICE_NAME" ] 
then
    echo "Directory /home/dockeru/$SERVICE_NAME exists." 
else
    echo "Error: Directory /home/dockeru/$SERVICE_NAME does not exists."
fi

# if [ -d "/home/dockeru/$DEPLOY_SCRIPT_NAME" ]
# then 
# cd /home/dockeru/$DEPLOY_SCRIPT_NAME && git pull; 
# else 
# git clone $DEPLOY_SCRIPT_GIT_URL; 
# fi
# cd /home/docker/$SERVICE_NAME
# git pull $SERVICE_BRANCH_NAME --force
