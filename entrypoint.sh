#!/bin/bash

function configure_authentication() {

    # Determine correct URL to use
    if [ -n "$GHES_HOSTNAME" ]; then
	if [ "$SUBDOMAIN_ISOLATION" = "false" ]; then
	    URL="https://${GHES_HOSTNAME}/_registry/maven/${OWNER}/${REPOSITORY}"
	else
	    URL="https://maven.${GHES_HOSTNAME}/${OWNER}/${REPOSITORY}"
	fi
    else
	URL="https://maven.pkg.github.com/${OWNER}/${REPOSITORY}"
    fi	


    # Copy system Maven settings to user settings
    mkdir ~/.m2
    cp /usr/share/maven/conf/settings.xml ~/.m2/settings.xml

    # Delete example servers entry and add the necessary values for this case
    xmlstarlet ed -L -d "/_:settings/_:servers" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings" -t elem -n servers -v "" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:servers" -t elem -n server -v "" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:servers/_:server" -t elem -n id -v "github" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:servers/_:server" -t elem -n username -v "${USER}" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:servers/_:server" -t elem -n password -v "${TOKEN}" ~/.m2/settings.xml

    # Delete example profiles entry and add the necessary values for this case
    xmlstarlet ed -L -d "/_:settings/_:profiles" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings" -t elem -n profiles -v "" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:profiles" -t elem -n profile -v "" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:profiles/_:profile" -t elem -n id -v "github" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:profiles/_:profile" -t elem -n repositories -v "" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:profiles/_:profile/_:repositories" -t elem -n repository -v "" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:profiles/_:profile/_:repositories/_:repository" -t elem -n id -v "github" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:profiles/_:profile/_:repositories/_:repository" -t elem -n url -v "${URL}" ~/.m2/settings.xml

    # Activate the profile
    xmlstarlet ed -L -s "/_:settings" -t elem -n activeProfiles -v "" ~/.m2/settings.xml
    xmlstarlet ed -L -s "/_:settings/_:activeProfiles" -t elem -n activeProfile -v "github" ~/.m2/settings.xml

}

function publish_maven_package() {

    # Create a new project
    mvn archetype:generate -DgroupId=${GROUP_ID} -DartifactId=${ARTIFACT_ID} -Dversion=${PACKAGE_VERSION} -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false --no-transfer-progress

    # Determine correct repository URL to use
    if [ -n "$GHES_HOSTNAME" ]; then
	if [ "$SUBDOMAIN_ISOLATION" = "false" ]; then
	    URL="https://${GHES_HOSTNAME}/_registry/maven/${OWNER}/${REPOSITORY}"
	else
	    URL="https://maven.${GHES_HOSTNAME}/${OWNER}/${REPOSITORY}"
	fi
    else
	URL="https://maven.pkg.github.com/${OWNER}/${REPOSITORY}"
    fi

    # Modify the pom.xml file to add the repository

    xmlstarlet ed -L -s "/_:project" -t elem -n distributionManagement -v "" ${ARTIFACT_ID}/pom.xml
    xmlstarlet ed -L -s "/_:project/_:distributionManagement" -t elem -n repository -v "" ${ARTIFACT_ID}/pom.xml
    xmlstarlet ed -L -s "/_:project/_:distributionManagement/_:repository" -t elem -n id -v "github" ${ARTIFACT_ID}/pom.xml
    xmlstarlet ed -L -s "/_:project/_:distributionManagement/_:repository" -t elem -n name -v "GitHub Package Registry" ${ARTIFACT_ID}/pom.xml
    xmlstarlet ed -L -s "/_:project/_:distributionManagement/_:repository" -t elem -n url -v "${URL}" ${ARTIFACT_ID}/pom.xml

    # Modify the pom.xml file to set maven compiler source and target to 11, which is the version of Java used in the container
    xmlstarlet ed -L -s "/_:project" -t elem -n properties -v "" ${ARTIFACT_ID}/pom.xml
    xmlstarlet ed -L -s "/_:project/_:properties" -t elem -n maven.compiler.source -v "11" ${ARTIFACT_ID}/pom.xml
    xmlstarlet ed -L -s "/_:project/_:properties" -t elem -n maven.compiler.target -v "11" ${ARTIFACT_ID}/pom.xml


    # Publish the package
    cd ${ARTIFACT_ID}
    mvn deploy -DskipTests 

}

function download_maven_package() {

    # Create a new project. The group ID, artifact ID, and version are generic because this project won't be published (we only use it to download the package)
    mvn archetype:generate -DgroupId=com.github.myapp -DartifactId=myapp -DarchetypeArtifactId=maven-archetype-quickstart -DinteractiveMode=false --no-transfer-progress

    # Determine correct repository URL to use
    if [ -n "$GHES_HOSTNAME" ]; then
	if [ "$SUBDOMAIN_ISOLATION" = "false" ]; then
	    URL="https://${GHES_HOSTNAME}/_registry/maven/${OWNER}/${REPOSITORY}"
	else
	    URL="https://maven.${GHES_HOSTNAME}/${OWNER}/${REPOSITORY}"
	fi
    else
	URL="https://maven.pkg.github.com/${OWNER}/${REPOSITORY}"
    fi

   # Add dependency to pom.xml

   xmlstarlet ed -L -s "/_:project/_:dependencies" -t elem -n dependency -v "" myapp/pom.xml
   xmlstarlet ed -L -s "/_:project/_:dependencies/_:dependency[last()]" -t elem -n groupId -v "${GROUP_ID}" myapp/pom.xml
   xmlstarlet ed -L -s "/_:project/_:dependencies/_:dependency[last()]" -t elem -n artifactId -v "${ARTIFACT_ID}" myapp/pom.xml
   xmlstarlet ed -L -s "/_:project/_:dependencies/_:dependency[last()]" -t elem -n version -v "${PACKAGE_VERSION}" myapp/pom.xml

   # Add URL of the repository to pom.xml

   xmlstarlet ed -L -s "/_:project" -t elem -n repositories -v "" myapp/pom.xml
   xmlstarlet ed -L -s "/_:project/_:repositories" -t elem -n repository -v "" myapp/pom.xml
   xmlstarlet ed -L -s "/_:project/_:repositories/_:repository[last()]" -t elem -n id -v "github" myapp/pom.xml
   xmlstarlet ed -L -s "/_:project/_:repositories/_:repository[last()]" -t elem -n name -v "GitHub Package Registry" myapp/pom.xml
   xmlstarlet ed -L -s "/_:project/_:repositories/_:repository[last()]" -t elem -n url -v "${URL}" myapp/pom.xml

   # Modify the pom.xml file to set maven compiler source and target to 11, which is the version of Java used in the container
   xmlstarlet ed -L -s "/_:project" -t elem -n properties -v "" myapp/pom.xml
   xmlstarlet ed -L -s "/_:project/_:properties" -t elem -n maven.compiler.source -v "11" myapp/pom.xml
   xmlstarlet ed -L -s "/_:project/_:properties" -t elem -n maven.compiler.target -v "11" myapp/pom.xml
   
   # Download the package
   cd myapp
   mvn install -DskipTests 

}


function validate_parameters() {

if [[ ! $USER =~ ^[a-z0-9-]+$ ]]; then
    echo "Invalid value for USER or USER not specified"
    exit 1
fi

if [ -z "$MODE" ]; then
    echo "MODE not set. Using default value 'publish'"
    MODE="publish"
fi

if [[ ! "$MODE" =~ ^(publish|download)$ ]]; then
    echo "MODE must be either 'publish' or 'download'"
    exit 1
fi

if [[ ! $TOKEN =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid value for TOKEN or TOKEN not specified"
    exit 1
fi

if [[ ! $OWNER =~ ^[a-z0-9-]+$ ]]; then
    echo "Invalid value for OWNER or OWNER not specified"
    exit 1
fi

if [ -z "$ARTIFACT_ID" ]; then
    echo "ARTIFACT_ID not set. Using ${OWNER}-test-package as default"
    ARTIFACT_ID="${OWNER}-test-package"
fi

if [[ ! $ARTIFACT_ID =~ ^[a-z0-9-]+$ ]]; then
    echo "Invalid value for ARTIFACT_ID"
    exit 1
fi

if [[ ! $GROUP_ID =~ ^[a-z0-9]+[a-z0-9.]*$ ]]; then
    echo "Invalid value for GROUP_ID or GROUP_ID not specified"
    exit 1
fi

if [ -z "$PACKAGE_VERSION" ]; then
    echo "PACKAGE_VERSION not set. Using 1.0.0 as default"
    PACKAGE_VERSION="1.0.0"
fi

if [[ ! $PACKAGE_VERSION =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(-((0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*)(\.(0|[1-9][0-9]*|[0-9]*[a-zA-Z-][0-9a-zA-Z-]*))*))?(\+([0-9a-zA-Z-]+(\.[0-9a-zA-Z-]+)*))?$ ]]; then
    echo "Invalid value for PACKAGE_VERSION or PACKAGE_VERSION not specified"
    exit 1
fi

if [[ ! $REPOSITORY =~ ^[a-z0-9-]+$ ]]; then
    echo "Invalid value for REPOSITORY or REPOSITORY not specified"
    exit 1
fi

if [ -n "$GHES_HOSTNAME" ]; then
    if [[ ! $GHES_HOSTNAME =~ ^[a-z0-9-]+[a-z0-9.-]*$ ]]; then
	echo "Invalid value for GHES_HOSTNAME"
	exit 1
    fi
fi

}

function main() {

    validate_parameters

    configure_authentication

    if [ "$MODE" = "publish" ]; then
	publish_maven_package
    elif [ "$MODE" = "download" ]; then
	download_maven_package
    fi
}

main

