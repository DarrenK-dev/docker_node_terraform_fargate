read -p "Tag and push new image to aws ecr (yes | no)?" push_new_image
./docker-auth.sh
./docker-build.sh
./terraform-plan.sh
./terraform-apply.sh
if [ $push_new_image == "Y" ] || [ $push_new_image == "y" ] || [ $push_new_image == "Yes" ] || [ $push_new_image == "yes" ] 
then
./tag-image-and-push-to-ecr.sh
fi