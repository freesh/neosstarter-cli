# init variables
echo "Please enter your project name:"
read project_name

echo "Please enter your sitepackage name (example: LeanWorks.Site):"
read sitepackage_name

echo "Please enter your site name (example: LeanWorks):"
read site_name

# init neos
echo "# create project"
composer create-project neos/neos-base-distribution $project_name
cd $project_name

# remove unused neos packages
echo "update composer dependencies"
composer --no-update remove neos/demo

# install dev packages
composer --no-update --dev require deployer/deployer sitegeist/magicwand
composer --no-update require sitegeist/klarschiff sitegeist/lazybones sitegeist/monocle

# process updates
composer update

# download templates
echo "# create ./docker-compose.yml"
curl --create-dirs -o ./docker-compose.yaml https://raw.githubusercontent.com/freesh/neosstarter-templates/main/Templates/docker-compose.yaml
echo "# create deployer configs"
curl --create-dirs -o ./hosts.yml https://raw.githubusercontent.com/freesh/neosstarter-templates/main/Templates/hosts.yaml
curl --create-dirs -o ./deploy.php https://raw.githubusercontent.com/freesh/neosstarter-templates/main/Templates/deploy.php
echo "# create ./Configuration/Development/Docker/mysql.cnf"
curl --create-dirs -o ./Configuration/Development/Docker/mysql.cnf https://raw.githubusercontent.com/freesh/neosstarter-templates/main/Templates/Configuration/Development/Docker/mysql.cnf
echo "# create ./Configuration/Development/Docker/Settings.yaml"
curl --create-dirs -o ./Configuration/Development/Docker/Settings.yaml https://raw.githubusercontent.com/freesh/neosstarter-templates/main/Templates/Configuration/Development/Docker/Settings.yaml

# update composer.json
composer config --json scripts.deploy:development 'bin/dep development'
composer config --json scripts.deploy:staging 'bin/dep staging'
composer config --json scripts.deploy:production 'bin/dep production'

# start docker
echo "# start docker"
docker-compose up -d

# setting um site and user
echo "# create site and user"
while ! mysqladmin ping -h0.0.0.0 --port=13306 --silent; do sleep 1 ;done
echo "# migrate"
export FLOW_CONTEXT=Development/Docker && ./flow doctrine:migrate
echo "# create user"
export FLOW_CONTEXT=Development/Docker && ./flow user:create admin admin Admin Admin --roles Administrator
echo "# create sitepackage"
export FLOW_CONTEXT=Development/Docker && ./flow kickstart:site $sitepackage_name $site_name
echo "# create site"
export FLOW_CONTEXT=Development/Docker && ./flow site:create $site_name $sitepackage_name $sitepackage_name:Document.Page
echo "# clear caches"
export FLOW_CONTEXT=Development/Docker && ./flow flow:cache:flush

echo "# git init"
git init
git add *
git commit -m "Initial Commit"

# ready message
echo "Congratulations your local Neos setup is ready!"
echo ""
echo "Backend  http://0.0.0.0:8081/neos"
echo "Frontend http://0.0.0.0:8081/"
echo ""
echo "Call flow commands: FLOW_CONTEXT=Development/Docker ./flow help"
echo ""
echo "Start: docker-compose up -d"
echo "Stop:  docker-compose down"
echo "Prune: docker-compose down -v"

export FLOW_CONTEXT=Development/Docker && ./flow flow:server:run -p 8081
