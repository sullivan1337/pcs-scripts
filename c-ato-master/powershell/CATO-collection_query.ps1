# CATO-collection_query.ps1
#
# This script is used for the "Continuous Authority to Operate" concepts to identify all vulnerabilities associated with a collection of images
# The output is a CSV file containing all the unique CVE/packages found in all the images within a collection.
# An ATO Auditor can make the determination of what Tag they want to associate with each CVE.
# The CSV file is then used as input for the CATO-tag_population.ps1 script to associate CVEs to Tags within the Console
#
# Logic:
#   1 - Generates a list of all the images within a Collection supplied as a command line argument
#   2 - Queries for unique images in Deployed Images, Registry and CI. Images found in multiple locations are counted once
#   3 - Calls "Unique_CVE" function to identify all the CVE/packages found in all the unique images
#   4 - Generates a CSV output file for the ATO Auditor to review and associate Tags
#
# Requires: powershell v6 https://blogs.msdn.microsoft.com/powershell/2018/01/10/powershell-core-6-0-generally-available-ga-and-supported/
# Discalimer: Use of this script does not imply any rights to Palo Alto Networks products and/or services.
#
# Debugging: $debugpreference = "continue" at the powershell command prompt for detailed output of the script

param($arg1,$arg2,$arg3,$arg4)


if(!$arg1)
    {
    write-host "Please provide a collection name"
    write-host "Usage: ./CATO-collection_query.ps1 <name of collection>"
    exit
    }
else
    {
    write-host "Checking for images within collection: $arg1"
    }
# variables
$tlconsole = $arg4
$collection_images = @()
$global:unique_cve = @() # array of unique CVEs
$global:cve_packages = @{} # hash table of CVEs and their associated packages
$global:newline = [System.Environment]::NewLine
$global:output_csv = "CVE,CVSS,PackageName,Status,Description,Tag" + $newline
$global:i = 0 # counter for unique vulnerabilities
$time = Get-Date -f "yyyyMMdd-HHmmss"

function Unique_CVE([string]$image_name, [array]$cves)
    {
    write-debug $image_name
    foreach($cve in $cves)
        {
        # temp variables, remove commas
        $tmpCVE = $cve.CVE
        $tmpPackageName = $cve.packageName -replace ",",""
        $tmpCveDescription = $cve.description -replace ",",""
        $tmpCveStatus = $cve.status -replace ",",""

        # Does the CVE exist in the hash table
        if(!$global:cve_packages.ContainsKey($cve.CVE))
            {
            # Add a new key and the packages associated with it
            $debug_output = "Adding CVE: " + $tmpCVE + "|" + $tmpPackageName
            write-debug $debug_output
            $global:cve_packages += @{$tmpCVE = $tmpPackageName}
            $global:i++
            # write to output csv string
            $global:output_csv = $global:output_csv + $cve.cve+","+$cve.cvss+","+$tmpPackageName+","+$tmpCveStatus+","+$tmpCveDescription + $newline

            # Add to array of CVEs in case we need it again
            $global:unique_cve += $tmpCVE
            }
        else
            {
            # CVE is a key in the hash table see if the package already accounted for
            # pull out the array of packages for the CVE in the hash table
            $tmpArray = [array]$global:cve_packages.$tmpCVE
            if($tmpArray.Contains($tmpPackageName))
                {
                # Already have this package
                $debug_output = "Already seen package: " + $cve.CVE + "|" + $tmpPackageName
                write-debug $debug_output
                }
            else
                {
                $global:i++
                # write to output csv string
                $global:output_csv = $global:output_csv + $cve.cve+","+$cve.cvss+","+$tmpPackageName+","+$tmpCveStatus+","+$tmpCveDescription + $newline

                $debug_output = "Adding package: " + $cve.CVE + "|" + $tmpPackageName
                write-debug $debug_output

                # Add package into the hash table
                $tmpArray += $tmpPackageName
                $global:cve_packages.$tmpCVE = $tmpArray
                }
            }
        } # end of foreach
    } # end of Unique_CVE function

# We will need credentials to connect so we will ask the user

$password = ConvertTo-SecureString $arg3 -AsPlainText -Force

$cred = New-Object System.Management.Automation.PSCredential ($arg2, $password)

# $cred = Get-Credential -Credential $arg3
#
# $cred = Get-Credential -UserName $arg2

# Look in Deployed Images
$request = "$tlconsole/api/v1/images?collections=$arg1"
$images = Invoke-RestMethod $request -Authentication Basic -Credential $cred -SkipCertificateCheck

# Go through the images
$debug_output = "Deployed Images: " + $images.count
write-debug $debug_output
if($images.count -gt 0)
    {
    foreach($image in $images)
        {
        $tmpImageName = $image.tags.repo + ":" + $image.tags.tag
        $debug_output = "`t" + $image._id + " | " + $tmpImageName
        write-debug $debug_output
        #add imageID into array of found images
        if($collection_images -notcontains $image._id)
            {
            $collection_images += $image._id
            # Send to Unique_CVE function
            Unique_CVE $tmpImageName $image.vulnerabilities
            }
        }
    }
else
    {
    write-debug "Did not find any deployed images, continuing"
    }

# Look in registry
$request = "$tlconsole/api/v1/registry?collections=$arg1"
$images = Invoke-RestMethod $request -Authentication Basic -Credential $cred -SkipCertificateCheck

# Go through the images
$debug_output = "Registry Images: " + $images.count
write-debug $debug_output
if($images.count -gt 0)
    {
    foreach($image in $images)
        {
        $tmpImageName = $image.id + " | " + $image[0]._id
        $debug_output = "`t$tmpImageName"
        write-debug $debug_output
        #add imageID into array of found images
        if($collection_images -notcontains $image.id)
            {
            $collection_images += $image.id
            $debug_output = "`t Adding new image: " + $image.id
            write-debug $debug_output
            # Send to Unique_CVE function
            Unique_CVE $tmpImageName $image.vulnerabilities
            }
        }
    }
else
    {
    write-debug "Did not find any registry images, continuing"
    }


# Look in CI
$request = "$tlconsole/api/v1/scans?collections=$arg1"
$images = Invoke-RestMethod $request -Authentication Basic -Credential $cred -SkipCertificateCheck

# Go through the images
$debug_output = "Scanned Images: " + $images.count
write-debug $debug_output
if($images.count -gt 0)
    {
    foreach($image in $images)
        {
        $tmpImageName = $image.entityinfo.repoTag.repo + ":" + $image.entityinfo.repoTag.tag
        $debug_output = "`t" + $image.entityInfo.id + " | " + $tmpImageName
        write-debug $debug_output
        #add imageID into array of found images
        if($collection_images -notcontains $image.entityInfo.id)
            {
            $collection_images += $image.entityInfo.id
            $debug_output = "`t Adding new image: " + $tmpImageName
            write-debug $debug_output
            # Send to Unique_CVE function
            Unique_CVE $tmpImageName $image.entityinfo.vulnerabilities
            }
        }
    }
else
    {
    write-debug "Did not find any scanned images"
    }

# Output images in the collection
if($collection_images.count -gt 0)
    {
    #debug print list of unique images
    $debug_output = "Images within the collection " + $arg1 + $collection_images.count
    write-debug $debug_output
    foreach($image in $collection_images)
        {
        write-debug `t$image
        }
    # debug output and unique CVEs and associated packages
    write-debug ($global:cve_packages|Out-String)

    #Output to file
    $outputFile = $time+"-"+$arg1+"-cves.csv"
    $global:output_csv | Out-File -FilePath .\$outputFile -Encoding ASCII
    write-host "Unique Images: " $collection_images.count
    write-host "Unique CVE/packages found: " $global:i
    write-host "Output CSV: $outputFile"
    }
else
    {
    write-host "No images found in collection: $arg1"
    }
