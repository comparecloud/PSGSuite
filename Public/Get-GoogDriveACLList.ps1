﻿function Get-GoogDriveACLList {
    [cmdletbinding(DefaultParameterSetName='InternalToken')]
    Param
    ( 
      [parameter(Mandatory=$false)]
      [string]
      $Owner = $Script:PSGoogle.AdminEmail,  
      [parameter(Mandatory=$true)]
      [String]
      $FileID,
      [parameter(Mandatory=$false)]
      [ValidateSet("v2","v3")]
      [string]
      $APIVersion="v3",
      [parameter(ParameterSetName='ExternalToken',Mandatory=$false)]
      [String]
      $AccessToken,
      [parameter(ParameterSetName='InternalToken',Mandatory=$false)]
      [ValidateNotNullOrEmpty()]
      [String]
      $P12KeyPath = $Script:PSGoogle.P12KeyPath,
      [parameter(ParameterSetName='InternalToken',Mandatory=$false)]
      [ValidateNotNullOrEmpty()]
      [String]
      $AppEmail = $Script:PSGoogle.AppEmail
    )
if (!$AccessToken)
    {
    $AccessToken = Get-GoogToken -P12KeyPath $P12KeyPath -Scopes "https://www.googleapis.com/auth/drive" -AppEmail $AppEmail -AdminEmail $Owner
    }
$header = @{
    Authorization="Bearer $AccessToken"
    }
$URI = "https://www.googleapis.com/drive/$APIVersion/files/$FileID/permissions"
if($APIVersion -eq "v3")
    {
    $URI = "$URI`?fields=permissions"
    }
try
    {
    $response = Invoke-RestMethod -Method Get -Uri $URI -Headers $header -ContentType "application/json" | Select-Object -ExpandProperty $(if($APIVersion -eq "v3"){"permissions"}elseif($APIVersion -eq "v2"){"items"})
    }
catch
    {
    try
        {
        $result = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($result)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $resp = $reader.ReadToEnd()
        $response = $resp | ConvertFrom-Json | 
            Select-Object @{N="Error";E={$Error[0]}},@{N="Code";E={$_.error.Code}},@{N="Message";E={$_.error.Message}},@{N="Domain";E={$_.error.errors.domain}},@{N="Reason";E={$_.error.errors.reason}}
        }
    catch
        {
        $response = $resp
        }
    }
return $response
}