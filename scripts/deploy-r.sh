#!/bin/bash
# @author Ashish Sahoo (ashissah@in.ibm.com)
############################################################################
#Environment Variables                                                     #
############################################################################
#
# export port_range=9443,8000
# export kluster=mycluster-free
# export rep_uri_docker=docker.io
# export rep_uri_ibmcloud=us.icr.io
############################################################################
#                 DOCKER HUB IMAGE PUSH                                    #
############################################################################
echo "Docker Push Images"
docker push "$DOCKER_USERNAME"/$git_repo:$TRAVIS_BRANCH-$DEPLOY_TIMESTAMP-$TRAVIS_BUILD_NUMBER
docker push "$DOCKER_USERNAME"/$git_repo:latest
# ############################################################################
# # Log into the IBM Cloud environment using apikey                          #
# ############################################################################
# echo "Login to IBM Cloud using apikey"
# ibmcloud login -a https://cloud.ibm.com --apikey $IC_API_KEY -r us-south
# if [ $? -ne 0 ]; then
#   echo "Failed to authenticate to IBM Cloud"
#   exit 1
# fi
# ############################################################################
# # Log into the IBM Cloud container registry                                #
# ############################################################################
# echo "Logging into IBM Cloud container registry"
# ibmcloud cr login
# if [ $? -ne 0 ]; then
#   echo "Failed to authenticate to IBM Cloud container registry"
#   exit 1
# fi
# ############################################################################
# # If the image exists in the container registry then delete it             #
# # then recreate it                                                         #
# ############################################################################
# echo "looking to see if the name-space exists"
# ibmcloud cr namespace-list | grep "$icp_name"
# if [ $? -ne 0 ]; then
#   echo "Name-space not exist in IBM Cloud container registry, Adding them now"
#   ibmcloud cr namespace-add "$icp_name"
# else
#   echo "Name-space exist in IBM Cloud container registry, Deleting and Adding them now"
#   ibmcloud cr namespace-rm "$icp_name" -f
#   ibmcloud cr namespace-add "$icp_name"
# fi
# ############################################################################
# # Build image with dockerfile in Cloud Registry                            #
# # It can be either from IBM Cloud or Docker, use accordingly               #
# ############################################################################
# # ibmcloud cr image-rm us.icr.io/"$icp_name"/"$git_repo"
# # ibmcloud cr image-list
# ############################################################################
# # Log into the IBM Cloud container registry                                #
# ############################################################################
# echo "Logging into IBM Cloud container registry"
# ibmcloud cr login
# if [ $? -ne 0 ]; then
#   echo "Failed to authenticate to IBM Cloud container registry"
#   exit 1
# fi
# #ibmcloud cr build --tag us.icr.io/"$icp_name"/"$git_repo" ./
# # docker tag $git_repo us.icr.io/"$icp_name"/"$git_repo"
# # docker push us.icr.io/"$icp_name"/"$git_repo"

# ############################################################################
# # Start the deployment details using kubectl                               #
# ############################################################################
# ibmcloud ks cluster config --cluster "$kluster"
# kubectl config current-context
# #
# echo 'Deleting the deployment' $git_repo
# kubectl delete -n default pod "$git_repo"
# kubectl delete -n default deployment "$git_repo" 
# #
# if [ $? -ne 0 ]; then
#   echo "Deployment does not exist in IBM Cloud container registry, Adding them now"
#   # kubectl create deployment $git_repo --image=us.icr.io/"$icp_name"/"$git_repo" 
#   # kubectl run $git_repo --image=us.icr.io/"$icp_name"/"$git_repo"
#   kubectl create deployment $git_repo --image="$rep_uri_docker"/"$icp_name"/"$git_repo" 
#   kubectl run $git_repo --image="$rep_uri_docker"/"$icp_name"/"$git_repo"

# else
#   echo "Deployment does exist in IBM Cloud container registry, Adding them now as deleted"
#   # kubectl create deployment $git_repo --image=us.icr.io/"$icp_name"/"$git_repo" 
#   kubectl create deployment $git_repo --image="$rep_uri_docker"/"$icp_name"/"$git_repo" 
#   echo "Run Deployment Start"
#   # kubectl run $git_repo --image=us.icr.io/"$icp_name"/"$git_repo"
#   kubectl run $git_repo --image="$rep_uri_docker"/"$icp_name"/"$git_repo"
#   echo "Run Deployment Ends"
# fi
# ############################################################################
# # Start the Service deployment details using kubectl                       #
# ############################################################################

#    echo 'Service deployment delete Start'
#    kubectl delete -n default service "$git_repo"-node
# #
#   echo "Run Deployment/Service Start"
#   kubectl expose deployment.apps/"$git_repo" --type=NodePort --name="$git_repo"-node --port="$port_range"
#   echo "Run Deployment/Service End"
# ############################################################################
# # Get details of the Service deployment  kubectl                           #
# ############################################################################
#   ibmcloud ks cluster ls
#   kubectl describe deployments "$git_repo"
#   ibmcloud ks worker ls --cluster "$kluster"
#   kubectl describe service "$git_repo"-node
# ############################################################################
# # Create Short url from Node/Node-port                                     #
# ############################################################################
#   # NODEPORT=$(kubectl get -o jsonpath="{.spec.ports[0].nodePort}" services "$git_repo"-node)
#   # NODES=$(kubectl get nodes -o jsonpath='{ $.items[*].status.addresses[?(@.type=="ExternalIP")].address }')
#   # echo $NODES
#   # echo $NODEPORT
#   # url=http://"$NODES":"$NODEPORT"
#   # short_url=$(curl -s http://tinyurl.com/api-create.php?url=${url})
#   # echo "Short URL is : ${short_url}"