rm -rf export/OpenOCL/
OCL_VERSION=6.01
DATESTR=$(date +"%Y\/%m\/%d")
DATEVERSION="$OCL_VERSION, $DATESTR"

git clone https://github.com/OpenOCL/OpenOCL.git openocl_repo
cd openocl_repo
git checkout-index -a -f --prefix=../export/OpenOCL/
cd ..
rm -rf openocl_repo
rm export/OpenOCL/.gitignore
rm export/OpenOCL/README.md

# set date and version in readme marked by $dateversion$
sed "s/#dateversion#/$DATEVERSION/g" README > export/OpenOCL/README
sed "s/#version#/$OCL_VERSION/g" ocl-version.m > export/OpenOCL/+ocl/version.m

cd export/OpenOCL
zip -r -q ../OpenOCL-v${OCL_VERSION}.zip .
cd ..
