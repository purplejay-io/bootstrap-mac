#!/bin/bash

if [[ ! -d "/Applications/Company Portal.app" ]];then
  sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Company%20Portal/installCompanyPortal.sh)"
fi
if [[ ! -d "/Applications/Microsoft Teams.app" ]];then
  sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Misc/Rosetta2/installRosetta2.sh)"
  sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Teams/installTeams.sh)"
fi
if [[ ! -d "/Applications/Microsoft Edge.app" ]];then
  sudo /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/microsoft/shell-intune-samples/master/Apps/Edge/installEdge.sh)"
fi
