
#!/bin/sh
#.Synopsis
#   Export des projets GNS3

#.DESCRIPTION
 #  Export des projets GNS3 avec les images,fichiers et machines virtuelles

#.EXAMPLE
#   ./Nom du script

#.NOTES
#    NAME:    Export projets GNS3
#    AUTHOR:    Fabien Mauhourat

#    VERSION HISTORY:

#    1.0 (beta)    2017.09.12   Fabien MAUHOURAT

#.FUNCTIONALITY
#    Export des projets GNS3 :
#        - Export des fichiers du projet contenue dans la VM GNS3
#        - Export des images du projet :
#            - QEMU
#            - IOS
#            - DOCKER
#            - IOU
#        - Export des machines virtuelles du projet
#>

# Fonction qui verifie les paramètres du script
function verify-param {
    if ( ! (ping $ip_vm_gns3 -n 2 | Select-String "TTL=") ) {
   do  echo "La vm GNS3 $ip_vm_gns3 n est pas accessible !"
        pause ; exit
    }
	fi
done
    if ( $gns3_proj_path_local -eq "" -or ! (Test-Path $gns3_proj_path_local) ) {
        echo "La variable gns3_proj_path_local n est pas definie !"
        pause ; exit
    }
    if ( $gns3_images_path_local -eq "" -or ! (Test-Path $gns3_images_path_local) ) {
        echo "La variable gns3_images_path_local n est pas definie !"
        pause ; exit
    }
    if ( $vmware_path_ovftool -eq "" -or ! (Test-Path $vmware_path_ovftool) ) {
        echo "La variable vmware_path_ovftool n est pas definie !"
        pause ; exit
    }
    if ( $export_project_path -eq "" -or ! (Test-Path $export_project_path) ) {
        echo "La variable export_project_path n est pas definie !"
        pause ; exit
    }
	if ( ! (Invoke-Command {& plink}) ) {
        echo "Putty n'est pas installe sur le poste ou le chemin n est pas dans la variable PATH !"
        pause ; exit
    }
	if ( ! (Invoke-Command {& pscp}) ) {
        echo "Putty n'est pas installe sur le poste ou le chemin n est pas dans la variable PATH !"
        pause ; exit
    }
    if ( $temp_path -eq "" ) {
        echo "La variable temp_path n est pas definie !"
        pause ; exit
    }
    if ( $pass_gns3_vm -eq "" ) {
        echo "La variable pass_gns3_vm n est pas definie !"
        pause ; exit
    }
    if ( $user_gns3_vm -eq "" ) {
        echo "La variable user_gns3_vm n est pas definie !"
        pause ; exit
    }
    if ( $gns3_proj_path_vm -eq "" ) {
        echo "La variable gns3_proj_path_vm n est pas definie !"
        pause ; exit
    }
	New-Item -ItemType Directory -Force -Path "$temp_path\GNS3-TEMP" | Out-Null
    if ( $? -eq 0 ) {
        echo "Creation du dossier GNS3-TEMP dans $temp_path echoue !"
        pause ; exit
    }
    $script:temp_path="$temp_path\GNS3-TEMP"

    echo ""
    echo "Verification des parametres terminee sans erreur !" -ForegroundColor Green
    echo ""
    echo "La configuration est la suivante :"
    echo "     * Chemin projects : $gns3_proj_path_local"
    echo "     * Chemin images : $gns3_images_path_local"
    echo "     * Chemin d export du project : $export_project_path"
    echo "     * IpVM GNS3 : $ip_vm_gns3"
    echo ""
}

# Fonction qui copie les images du project
function copie-images {

    Param(
      [string]$source,
      [string]$dest,
      [string]$images_name
    )

    cp -Force -Path "$source" -Destination "$temp_path\$nom_project\images\$dest"
    
    if ( $? -eq 0 ) {
        echo "Export de l image $images echoue !"
        delete_temp
    }

    echo ""
    echo "Export de l image $images_name terminee !" -ForegroundColor Green
    echo ""
}

# Fonction qui verifie si l image existe deja
function verify_images {

    Param(
      [string]$images_name,
      [string]$type
    )

    $images_test=Get-ChildItem -Path "$temp_path\$nom_project\images\$type" | where {$_ -match "^$($images_name)$"}
    return "$images_test"
}

# Fonction qui cherche les images du project
function find_images {

    Param(
      [string]$images_name
    )

    $images_path_temp=Get-ChildItem -Path "$gns3_images_path_local" -Recurse | where {$_ -match "^$($images_name)$"}

    if ( "$images_path_temp" -eq ""  ) {
        echo "Images $images introuvable dans le repertoire $gns3_images_path_local !"
        delete_temp
    }

    $images_path=$images_path_temp.PSPath | % {$_.split('::')[2] + ":" + $_.split('::')[3]}

    return $images_path
}

# Fonction qui execute une commande ssh
function ssh_command {

    Param(
      [string]$command
    )

    plink.exe -pw "$pass_gns3_vm" "$user_gns3_vm@$ip_vm_gns3" "$command" | Out-Null 

    if ( $? -eq 0 ) {
        echo "Commande $command a echoue sur l hote $ip_vm_gns3 avec l utilisateur $user_gns3_vm !"
        delete_temp
    }
}

# Fonction qui copie des fichiers en ssh
function ssh_copie {

    Param(
      [string]$source,
      [string]$dest
    )

    pscp.exe -pw "$pass_gns3_vm" -r "$user_gns3_vm@$($ip_vm_gns3):$source" "$dest" | Out-Null

    if ( $? -eq 0 ) {
        echo "La copie des fichiers $source vers $dest a echoue !"
        delete_temp
    }
}

# Fonction qui affiche les erreurs du script
function echo {
    
    echo ""
    Write-Error "$args"
    echo ""

}

# Fonction qui supprime les fichiers temporaires du script
function delete_temp {

    Remove-Item -Force -Recurse $temp_path
    pause ; exit

}

write-output "###########################################################################"
write-output "################## Script d exportation des projets GNS3 ##################"
write-output "###########################################################################"

# Définition des variables
$gns3_proj_path_local="D:\Soft\GNS3\projects"
$gns3_images_path_local="D:\Soft\GNS3\images"
$ip_vm_gns3="192.168.0.50"
$gns3_proj_path_vm="/opt/gns3/projects"
$pass_gns3_vm="gns3"
$user_gns3_vm="gns3"
$vmware_path_ovftool="C:\Program Files (x86)\VMware\VMware Workstation\OVFTool\ovftool.exe"
$temp_path="D:\Temp"
$export_project_path="D:\Temp"

# Vérification des paramètres
verify-param

# Choix du project GNS3 à exporter

echo "Liste des projects GNS3 :" -ForegroundColor Green
echo ""

# Liste les projets GNS3 du repertoire gns3_proj_path_local
$compteur=0
Get-ChildItem $gns3_proj_path_local | select Name | foreach { 
    if (Test-Path "$gns3_proj_path_local\$($_.name)\$($_.name).gns3") {
        $compteur=$compteur+1
        echo "$compteur." $_.name`
    }
}

echo ""
$num_project=$(Read-Host "Quel project ")
echo ""

# Récuperation du nom du projet
$compteur=0
Get-ChildItem $gns3_proj_path_local | foreach { 
    if (Test-Path "$gns3_proj_path_local\$($_.name)\$($_.name).gns3") {
        $compteur=$compteur+1
        if ( $compteur -like $num_project ) {
            $nom_project=$_.Name
            return
        }
    }
}

echo "Projet $nom_project selectionne !" -ForegroundColor Green

# Recuperation de l'ID du project et le chemin du vmx des vm du project

$project_file=Get-Content "$gns3_proj_path_local\$nom_project\$nom_project.gns3" | ConvertFrom-Json

$vm_project=$($project_file.topology.nodes) | where {$_.node_type -match "vmware"}

$image_project=$($project_file.topology.nodes)

echo "      *  L ID du projet : $($project_file.project_id)"

# Copie du project dans le répertoire temporaire

Copy-Item -Recurse -Force -Path "$gns3_proj_path_local\$nom_project" -Destination "$temp_path"

if ( $? -eq 0 ) {
    echo "Copie du projet $nom_project echoue !"
    delete_temp
}

echo ""
echo "Copie du projet $nom_project reussi dans $temp_path\$nom_project !" -ForegroundColor Green

# Récuperation des données du project de la vm gns3

ssh_command "cd $gns3_proj_path_vm/$($project_file.project_id)" 

ssh_copie "$gns3_proj_path_vm/$($project_file.project_id)/project-files" "$temp_path\$nom_project"

echo ""
echo "Copie des fichiers du project $nom_project reussi dans $temp_path\$nom_project\project-files !" -ForegroundColor Green

# Creation de l'arborescence pour stocker les images dans le project

New-Item -ItemType Directory -Force -Path $temp_path\$nom_project\images | out-null

if ( $? -eq 0 ) {
    echo "Creation du repertoire $temp_path\$nom_project\images echoue !"
    delete_temp
}
foreach ($nodes in "QEMU","IOU","IOS","docker") {

    New-Item -ItemType Directory -Force -Path $temp_path\$nom_project\images\$nodes | out-null

    if ( $? -eq 0 ) {
        echo "Creation du dossier $temp_path\$nom_project\images\$nodes echoue !"
        delete_temp
    }
}

# Export des images du project

foreach ($images in $image_project) {

    # Export des images QEMU dans le repertoire temporaire du projet
    if ($($images.node_type) -match "qemu") {

        foreach ($lettre in "a","b","c","d") {

            $image_file_name="$($images.properties | select -ExpandProperty hd$($lettre)_disk_image)"
            
            if ( ! ("$image_file_name" -eq "") ) {

                if ( $(verify_images "$image_file_name" "QEMU") ) {continue}
                $images_path_local=find_images "$image_file_name"
                copie-images "$images_path_local" "QEMU" "$image_file_name"
            } else {
                continue
            } 
        }
        continue
    }

    # Export des images IOU dans le repertoire temporaire du projet
    elseif ($($images.node_type) -match "iou") {
        
        $image_file_name="$($images.properties.path)"
        if ( $(verify_images "$image_file_name" "IOU") ) {continue}
        $images_path_local=find_images "$image_file_name"
        copie-images "$images_path_local" "IOU" "$image_file_name"
        continue
    }

    # Export des images DOCKER dans le repertoire temporaire du projet
    elseif ($($images.node_type) -match "docker") {

        if ($($images.properties.image) -match "/") {
            $container_name=$($images.properties.image).split('/')[1]
        } else {
            $container_name=$($images.properties.image)
        }
        if ($($images.properties.image) -match ":") {
            $container_name=$container_name.split(':')[0]
        }
        echo $container_name
        if ( $(verify_images "$container_name" "docker") ) {continue}
        ssh_command "docker save $($images.properties.image) > /tmp/$container_name.tar"
        ssh_copie "/tmp/$container_name.tar" "$temp_path\$nom_project\images\docker\$container_name.tar"
        continue
    }

    # Export des images IOS dans le repertoire temporaire du projet
    elseif ($($images.node_type) -match "dynamips") {
        
        $image_file_name="$($images.properties.image)"
        if ( $(verify_images "$image_file_name" "IOS") ) {continue}
        $images_path_local=find_images "$image_file_name"
        copie-images "$images_path_local" "IOS" "$image_file_name"
        continue
    }   

}

echo ""
echo "Export des images dans $temp_path\$nom_project\images terminee avec succes !" -ForegroundColor Green
echo ""

# Export des vms du project en ovf

foreach ($vm in $($vm_project.properties.vmx_path)) {

    echo ""
    echo "Export de la VM $vm en cours !" -ForegroundColor Green
    echo ""

    Invoke-Command {& $vmware_path_ovftool $vm $temp_path}

    if ( $? -eq 0 ) {
        echo "Export de la VM $vm echoue !"
        delete_temp
    }
}

echo ""
echo "Export des VMs dans $temp_path terminee avec succes !" -ForegroundColor Green
echo ""

# Compression du project

Compress-Archive -Force -CompressionLevel Optimal -Path "$temp_path\*" -DestinationPath "$export_project_path\$nom_project"

if ( $? -eq 0 ) {
    echo "Compression du projet $nom_project echoue !"
    delete_temp
}

echo ""
echo "Compression du $nom_project reussi dans $export_project_path\$nom_project !" -ForegroundColor Green

echo ""
echo "Script termine avec succes !" -ForegroundColor Green

# Vidage des fichiers temporaire
delete_temp
