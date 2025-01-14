function Get-MetadataXML {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [String]$WebRequest,

        [Parameter(Mandatory = $true)]
        [String]$Url,

        [Parameter(Mandatory = $false)]
        [ValidateSet('fakku', 'panda')]
        [String]$Provider = 'fakku'
    )

    Switch ($Provider) {
        'fakku' {
            $Title = Get-FakkuElement -Webrequest $WebRequest -Name 'title'
            $Series = Get-FakkuElement -WebRequest $WebRequest -Name 'collections'
            $SeriesNumber = Get-FakkuChapter -WebRequest $WebRequest -Url $Url
            $SeriesGroup = Get-FakkuElement -WebRequest $WebRequest -Name 'magazines'
            if (-not $SeriesGroup) { $SeriesGroup = Get-FakkuElement -WebRequest $WebRequest -Name 'events' }
            $Summary = Get-FakkuElement -WebRequest $WebRequest -Name 'description'
            $Artist = Get-FakkuElement -WebRequest $WebRequest -Name 'artists'
            $Circle = Get-FakkuElement -WebRequest $WebRequest -Name 'circles'
            $Publisher = Get-FakkuElement -WebRequest $WebRequest -Name 'publishers'
            $Tags = Get-FakkuElement -WebRequest $WebRequest -Name 'tags'
            $Parody = Get-FakkuElement -WebRequest $WebRequest -Name 'series'
        }

        'panda' {
            $Title = Get-PandaTitle -Webrequest $WebRequest
            $SeriesGroup = Get-PandaSeries -WebRequest $WebRequest
            $Summary = Get-PandaSummary -WebRequest $WebRequest
            $Artist = Get-PandaArtist -WebRequest $WebRequest
            $Publisher = Get-PandaPublisher -WebRequest $WebRequest
            $Tags = Get-PandaGenres -WebRequest $WebRequest
        }
    }
    # Month/Year from magazine name
    if ($SeriesGroup -match '\b\d{4}\b') { $Year = $Matches.Values }
    if ($SeriesGroup -match '\b-\d{2}\b') { $Month = $SeriesGroup.Substring($SeriesGroup.Length - 2) }

    # Writes XML in a less hacky way than previously
    # This encodes XML reserved characters automatically
    $StringWriter = New-Object IO.StringWriter
    $XmlWriter = New-Object XML.XmlTextWriter($StringWriter)

    # XML settings
    $XmlWriter.Formatting = 'Indented'
    $XmlWriter.Indentation = 2
    $XmlWriter.IndentChar = ' '

    # Start writing
    $XmlWriter.WriteStartElement('ComicInfo')
    $XmlWriter.WriteAttributeString('xmlns:xsd', 'http://www.w3.org/2001/XMLSchema')
    $XmlWriter.WriteAttributeString('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
    $XmlWriter.WriteElementString('Title', $Title)
    # Fallback as single-entry series with title as name
    if ($Series) {
        $XmlWriter.WriteElementString('Series', $Series)
    } else {
        $XmlWriter.WriteElementString('Series', $Title)
    }
    # Fallback as single-entry of series
    if ($SeriesNumber) {
        $XmlWriter.WriteElementString('Number', $SeriesNumber)
    } else {
        $XmlWriter.WriteElementString('Number', '1')
    }
    # if ($Parody) { $XmlWriter.WriteElementString('AlternateSeries', $Parody) }
    $XmlWriter.WriteElementString('Summary', $Summary)
    if ($Year) { $XmlWriter.WriteElementString('Year', $Year) }
    if ($Month) { $XmlWriter.WriteElementString('Month', $Month) }
    $XmlWriter.WriteElementString('Writer', $Artist)
    $XmlWriter.WriteElementString('Publisher', $Publisher)
    if ($Circle) { $XmlWriter.WriteElementString('Imprint', $Circle) }
    $XmlWriter.WriteElementString('Tags', $Tags)
    if ($Parody) { $XmlWriter.WriteElementString('Genre', $Parody) }
    $XmlWriter.WriteElementString('Web', $Url)
    $XmlWriter.WriteElementString('LanguageISO', 'en')
    $XmlWriter.WriteElementString('Manga', 'Yes')
    # $XmlWriter.WriteElementString('SeriesGroup', ($Parody, $SeriesGroup) -join ', ' )
    $XmlWriter.WriteElementString('SeriesGroup', $SeriesGroup)
    $XmlWriter.WriteElementString('AgeRating', 'Adults Only 18+')
    # TO-DO - Get ISBN via some API
    if ($Tags -match 'book') { $XmlWriter.WriteElementString('GTIN', '') }
    $XmlWriter.WriteEndElement()

    $XmlWriter.Flush()
    $StringWriter.Flush()

    Write-Output $StringWriter.ToString()
}
