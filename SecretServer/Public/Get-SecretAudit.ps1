﻿function Get-SecretAudit {
    <#
        .SYNOPSIS
            Get audit trail for a secret from secret server

        .DESCRIPTION
            Get audit trail for a secret from secret server

        .PARAMETER SearchTerm
            If specified, obtain audit trail for all passwords matching this search term.  Accepts wildcards as '*'.

        .PARAMETER SecretId
            Secret Id to audit.

        .PARAMETER Uri
            uri for your win auth web service.

        .PARAMETER WebServiceProxy
            Existing web service proxy from SecretServerConfig variable

        .EXAMPLE
            Get-SecretAudit -SearchTerm "SQL"

            #Get all secret audit records for secrets that matched the searchterm SQL

        .EXAMPLE
            Get-SecretAudit -SecretId 5

            #Get all secret audit records for secret with ID 5

        .EXAMPLE
            Get-Secret -SearchTerm "SQL" | Get-SecretAudit

            #Functional equivalent to Get-SecretAudit -SearchTerm "SQL"

        .FUNCTIONALITY
            Secret Server
    #>
    [CmdletBinding()]
    param(
        [string]$SearchTerm = $null,

        [Parameter( Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            ValueFromRemainingArguments=$false,
            Position=1)]
        [int[]]$SecretId,

        [string]$Uri = $SecretServerConfig.Uri,
        [System.Web.Services.Protocols.SoapHttpClientProtocol]$WebServiceProxy = $SecretServerConfig.Proxy,
        [string]$Token = $SecretServerConfig.Token        
    )
    begin {
        if(-not $WebServiceProxy.whoami) {
            Write-Warning "Your SecretServerConfig proxy does not appear connected.  Creating new connection to $uri"
            try {
                $WebServiceProxy = New-WebServiceProxy -uri $Uri -UseDefaultCredential -ErrorAction stop
            }
            catch {
                Throw "Error creating proxy for $Uri`: $_"
            }
        }
        
        #spit out errors and results for given id
        function Get-SSSecAudit {
            [CmdletBinding()]
            param($id)
            if($Token) {
                $result = $WebServiceProxy.GetSecretAudit($Token,$id)
            }
            else {
                $result = $WebServiceProxy.GetSecretAudit($id)
            }

            $result.PSTypeNames.Insert(0,"SecretServer.SecretAudit")
            if($result.Errors) {
                Write-Error "Error obtaining Secret Audit for $id`:`n$($Result.Errors | Out-String)"
            }
            if($result.SecretAudits) {
                $result.SecretAudits
            }
        }

        #Search for secrets if searchterm was specified
        if($SearchTerm) {
            Write-Verbose "Calling Get-Secret for searchterm $SearchTerm"
            @( Get-Secret -SearchTerm $SearchTerm ) | ForEach-Object {
                Get-SSSecAudit -id $_.SecretId
            }
        }

    }
    process
    {
        foreach($Id in $SecretId) {
            Get-SSSecAudit -id $Id
        }   
    }
}

#publish
New-Alias -Name Get-SSSecretAudit -Value Get-SecretAudit -Force
#endpublish