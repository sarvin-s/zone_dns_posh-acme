function Get-CurrentPluginType { 'dns-01' }

function Add-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ZnUser,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$ZnApiKey,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=3)]
        [string]$ZnApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $zoneApiRoot = 'https://api.zone.eu/v2'

    $PSBoundParameters.Add('ZnApiRoot',$zoneApiRoot)
    
    $restParams = Get-ZnRestParams @PSBoundParameters

    $zoneName = Find-ZnZone $RecordName $restParams
    Write-Verbose "found $zoneName"

    $rec = Invoke-ZnRest "/dns/$zoneName/txt" @restParams

    if ($rec -and ($rec.name -ieq $RecordName)) {
        if ($rec | Where-Object { $_.name -eq $RecordName -and $_.destination -eq $TxtValue}){
            Write-Verbose "Record $RecordName with value $TxtValue already exist. Nothing to do."
        } else {
            Write-Verbose "Update the TXT record for $RecordName with value $TxtValue"
            $recToUpdate = $rec | Where-Object { $_.name -eq "$($RecordName)"} 

            $recId = $recToUpdate.id
            $recBody = @{
                name = $RecordName
                destination = $TxtValue
            } | ConvertTo-Json -Compress
    
            # update record
            Invoke-ZnRest "/dns/$zoneName/txt/$recId" `
                -Method PUT -Body $recBody @restParams | Out-Null
        }
    } else {
        Write-Verbose "Adding a TXT record for $RecordName with value $TxtValue"
        # build the new record object
        $recBody = @{
            name = $RecordName
            destination = $TxtValue
        } | ConvertTo-Json -Compress

        # add record
        Invoke-ZnRest "/dns/$zoneName/txt" `
            -Method POST -Body $recBody @restParams | Out-Null
    }

    <#
    .SYNOPSIS
        Add a DNS TXT record to zone.eu DNS

    .DESCRIPTION
        Uses the zone.eu API to add or update a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ZnUser
        The username for your zone.eu account.

    .PARAMETER ZnApiKey
        The API key for your zone.eu account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $ZnUser = Read-Host 'Username'
        $ZnApiKey = Read-Host 'Apikey' -AsSecureString
        Add-DnsTxt '_acme-challenge.example.com' 'txt-value' $ZnUser $ZnApiKey

        Adds or updates the specified TXT record with the specified value.
    #>
}

function Remove-DnsTxt {
    [CmdletBinding()]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [string]$TxtValue,
        [Parameter(Mandatory,Position=2)]
        [string]$ZnUser,
        [Parameter(ParameterSetName='Secure',Mandatory,Position=3)]
        [securestring]$ZnApiKey,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory,Position=3)]
        [string]$ZnApiKeyInsecure,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    $zoneApiRoot = 'https://api.zone.eu/v2'

    $PSBoundParameters.Add('ZnApiRoot',$zoneApiRoot)
    
    $restParams = Get-ZnRestParams @PSBoundParameters

    $zoneName = Find-ZnZone $RecordName $restParams
    Write-Verbose "found $zoneName"

    $rec = Invoke-ZnRest "/dns/$zoneName/txt" @restParams
    if ($rec -and ($rec.name -ieq $RecordName)) {
        $recToDelete = $rec | Where-Object { $_.name -eq $RecordName -and $_.destination -eq $TxtValue}
        if ($recToDelete) {
            Write-Verbose "Deleting record $RecordName with value $TxtValue."
            $recId = $recToDelete.id

            # delete record
            Invoke-ZnRest "/dns/$zoneName/txt/$recId" `
                -Method DELETE @restParams | Out-Null
        } else {
            Write-Verbose "Record $RecordName with value $TxtValue doesn't exist. Nothing to do."
        }
    } else {
        Write-Verbose "No records for $RecordName exist for zone $zoneName. Nothing to do."
    }

    # Do work here to remove the TXT record. Remember to add @script:UseBasic
    # to all calls to Invoke-RestMethod or Invoke-WebRequest.

    <#
    .SYNOPSIS
        Removes a DNS TXT record from zone.eu DNS

    .DESCRIPTION
        Uses the zone.eu API to remove a DNS TXT record.

    .PARAMETER RecordName
        The fully qualified name of the TXT record.

    .PARAMETER TxtValue
        The value of the TXT record.

    .PARAMETER ZnUser
        The username for your zone.eu account.

    .PARAMETER ZnApiKey
        The API key for your zone.eu account.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.

    .EXAMPLE
        $ZnUser = Read-Host 'Username'
        $ZnApiKey = Read-Host 'Apikey' -AsSecureString
        Remove-DnsTxt '_acme-challenge.example.com' 'txt-value' $ZnUser $ZnApiKey

        Removes the specified TXT record with the specified value.
    #>
}

function Save-DnsTxt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )
    <#
    .SYNOPSIS
        Not required.

    .DESCRIPTION
        This provider does not require calling this function to commit changes to DNS records.

    .PARAMETER ExtraParams
        This parameter can be ignored and is only used to prevent errors when splatting with more parameters than this function supports.
    #>
}


############################
# Helper Functions
############################

# API Docs (in estonian langauage only):
# https://help.zone.eu/kb/zone-api/
# https://api.zone.eu/v2

function Get-ZnRestParams {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$RecordName,
        [Parameter(Mandatory)]
        [string]$TxtValue,
        [Parameter(Mandatory)]
        [string]$ZnUser,
        [Parameter(ParameterSetName='Secure',Mandatory)]
        [securestring]$ZnApiKey,
        [Parameter(ParameterSetName='DeprecatedInsecure',Mandatory)]
        [string]$ZnApiKeyInsecure,
        [Parameter(Mandatory,Position=4)]
        [string]$ZnApiRoot,
        [Parameter(ValueFromRemainingArguments)]
        $ExtraParams
    )

    if ('Secure' -eq $PSCmdlet.ParameterSetName) {
        $ZnApiKeyInsecure = [pscredential]::new('a',$ZnApiKey).GetNetworkCredential().Password
    }

    $authToken = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes(($ZnUser,$ZnApiKeyInsecure -join ":")))

    # return the passed in values
    return @{
        ApiHost = $ZnApiRoot
        UserName = $ZnUser
        AuthToken = $authToken
    }
}

Function Invoke-ZnRest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$Path,
        [Parameter(Position=1)]
        [ValidateSet('GET','PUT','POST','DELETE')]
        [string]$Method = 'GET',
        [string]$Body,
        [string]$AcceptHeader = 'application/json',
        [Parameter(Mandatory)]
        [string]$ApiHost,
        [Parameter(Mandatory)]
        [string]$UserName,
        [Parameter(Mandatory)]
        [string]$AuthToken
    )

    $uri = [uri]"$($ApiHost)$($Path)"
    $Method = $Method.ToUpper()

    $headers = @{
        Authorization = "Basic $AuthToken"
        Accept = $AcceptHeader
    }
    
    # build the call parameters
    $irmParams = @{
        Method = $Method
        Uri = $uri
        Headers = $headers
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }
    if ($Body) {
        $irmParams.Body = $Body
    }
   
    try {
        Invoke-RestMethod @irmParams @script:UseBasic
    } catch {
        # ignore 404 errors and just return $null
        # otherwise, let it through
        if ([Net.HttpStatusCode]::NotFound -eq $_.Exception.Response.StatusCode) {
            return $null
        } else { throw }
    }
}

function Find-ZnZone {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,Position=0)]
        [string]$RecordName,
        [Parameter(Mandatory,Position=1)]
        [hashtable]$RestParams
    )

    # setup a module variable to cache the record to zone ID mapping
    # so it's quicker to find later
    if (!$script:ZnRecordZones) { $script:ZnRecordZones = @{} }

    # check for the record in the cache
    if ($script:ZnRecordZones.ContainsKey($RecordName)) {
        return $script:ZnRecordZones.$RecordName
    }

    # Search for the zone from longest to shortest set of FQDN pieces.
    # As zone.eu API does not support the search, an A record for the each expected zone should be requested
    $pieces = $RecordName.Split('.')
    for ($i=0; $i -lt ($pieces.Count-1); $i++) {
        $zone = $pieces[$i..($pieces.Count-1)] -join '.'
        Write-Debug "Checking $zone"
        try {
            $response = Invoke-ZnRest "/dns/$zone/a" @RestParams
            if ($response.name -contains $zone) {
                $script:ZnRecordZones.$RecordName = $zone
                return $zone
            }
        } catch { throw }
    }

    throw "No zone found for $RecordName"
}