function Get-FakkuMagazine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest
    )

    $Group = ($WebRequest -split '(?s)<a href="\/magazines\/.*?>(.*?)<\/a>')[1]?.Trim()
    if (-Not $Group) {
        $Group = ($WebRequest -split '(?s)<a href="\/events\/.*?>(.*?)<\/a>')[1]?.Trim()
    }

    Write-Output ([Net.WebUtility]::HtmlDecode($Group))
}