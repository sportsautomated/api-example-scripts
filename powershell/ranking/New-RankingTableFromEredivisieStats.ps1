If (-not [String]::IsNullOrEmpty($ApiKey))
{
  $Headers = @{ "X-API-KEY" = $ApiKey }
}
Else 
{
  $Headers = @{}
}


$SourceUri = "https://eredivisiestats.nl/wedstrijden.php"
$Body = "sorteer1=datum+ASC&sorteer2=thuisclub+ASC&submit=OK&datum1_dag=1&datum1_maand=1&datum1_jaar=1956&datum2_dag=1&datum2_maand=1&datum2_jaar=1956&seizoen%5B%5D=2021-2022&club%5B%5D=ADO&club%5B%5D=ADO+Den+Haag&club%5B%5D=Ajax&club%5B%5D=Alkmaar&club%5B%5D=AZ&club%5B%5D=AZ+%6067&club%5B%5D=Blauw+Wit&club%5B%5D=BVC+Amsterdam&club%5B%5D=BVV&club%5B%5D=BVV+Den+Bosch&club%5B%5D=Cambuur+Leeuwarden&club%5B%5D=De+Graafschap&club%5B%5D=De+Volewijckers&club%5B%5D=Dordrecht+%6090&club%5B%5D=DOS&club%5B%5D=DS+%6079&club%5B%5D=DWS&club%5B%5D=DWS%2FA&club%5B%5D=Eindhoven&club%5B%5D=Elinkwijk&club%5B%5D=Excelsior&club%5B%5D=FC+Amsterdam&club%5B%5D=FC+Den+Bosch&club%5B%5D=FC+Den+Haag&club%5B%5D=FC+Dordrecht&club%5B%5D=FC+Groningen&club%5B%5D=FC+Twente&club%5B%5D=FC+Twente+%6065&club%5B%5D=FC+Utrecht&club%5B%5D=FC+Volendam&club%5B%5D=FC+VVV&club%5B%5D=FC+Wageningen&club%5B%5D=FC+Zwolle&club%5B%5D=Feijenoord&club%5B%5D=Feyenoord&club%5B%5D=Fortuna+Sittard&club%5B%5D=Fortuna+%6054&club%5B%5D=FSC&club%5B%5D=Go+Ahead&club%5B%5D=Go+Ahead+Eagles&club%5B%5D=GVAV&club%5B%5D=Haarlem&club%5B%5D=Helmond+Sport&club%5B%5D=Heracles&club%5B%5D=Heracles+Almelo&club%5B%5D=Holland+Sport&club%5B%5D=MVV&club%5B%5D=NAC&club%5B%5D=NAC+Breda&club%5B%5D=NEC&club%5B%5D=NOAD&club%5B%5D=PEC+Zwolle&club%5B%5D=PSV&club%5B%5D=Rapid+JC&club%5B%5D=RBC+Roosendaal&club%5B%5D=RKC&club%5B%5D=RKC+Waalwijk&club%5B%5D=Roda+JC&club%5B%5D=SC+Cambuur&club%5B%5D=SC+Enschede&club%5B%5D=SC+Heerenveen&club%5B%5D=SC+Heracles&club%5B%5D=SHS&club%5B%5D=Sittardia&club%5B%5D=Sparta&club%5B%5D=Sparta+Rotterdam&club%5B%5D=SVV&club%5B%5D=SVV%2FDordrecht+%6090&club%5B%5D=Telstar&club%5B%5D=Veendam&club%5B%5D=Vitesse&club%5B%5D=Volendam&club%5B%5D=VVV&club%5B%5D=VVV-Venlo&club%5B%5D=Willem+II&club%5B%5D=Xerxes&club%5B%5D=Xerxes%2FDHC+%6066"
$PageRes = Invoke-WebRequest -Uri $SourceUri -Body $Body -Method Post -UseBasicParsing

$RequestBody = @{
  teams = @()
  matches = @()
  orderRules = @("OrderByTeamName", "OrderByTotalPoints", "OrderByGoalDifference", "OrderByGoalsFor")
  pointsGrants = @{
      pointsForLose = 0
      pointsForWin = 3
      pointsForDraw = 1
  }
}

$RegularExpression = "^<tr><td>(\d+\-\d+)<\/td><td>(\d{4}-\d{2}-\d{2})<\/td><td.+\/>(.+)<\/td><td nowrap.+\/>(.+)<\/td><td>(\d)<\/td><td>(\d)<\/td><\/tr>`$"
$SoccerMatches = [RegEx]::Matches($PageRes.Content, $RegularExpression, [System.Text.RegularExpressions.RegexOptions]::Multiline)
ForEach($Match in $SoccerMatches)
{
  $RequestBody.matches += @{
    teamHome = @{ name = $Match.Groups[3].ToString().Trim(); uniqueId = $Match.Groups[3].ToString().Trim(); }
    teamAway = @{ name = $Match.Groups[4].ToString().Trim(); uniqueId = $Match.Groups[4].ToString().Trim(); }
    homeScore = [Int] $Match.Groups[5].ToString().Trim()
    awayScore = [Int] $Match.Groups[6].ToString().Trim()
    matchDateTimeUtc = $Match.Groups[2].ToString().Trim().Replace("-", "")
    matchState = "Finished"
  }
}

$Res = $Null

$Stopwatch =  [System.Diagnostics.Stopwatch]::StartNew()
$Uri = "https://api.sportsautomated.com/api/ranking/generate"
$Res = Invoke-WebRequest -Method "POST" -UseBasicParsing -Uri $Uri -Body ($RequestBody | ConvertTo-Json -Compress -Depth 8) -ContentType "application/json" -Headers $Headers
$Res = $Res.Content | ConvertFrom-Json
$Stopwatch.Stop()

#Clear-Host
"Eredivisie data retrieved from eredivisiestats.nl." | Write-Host
"" | Write-Host 

"API request took {0} ms for {1} matches" -f $Stopwatch.ElapsedMilliseconds, $RequestBody.matches.Count | Write-Host 
" # {0} GP  W   D   L   P   F   A   GD  PD  FORM" -f "Name".PadRight(30, " ") | Write-Host 
"-".PadRight(75, "-") | Write-Host 
ForEach($Item in $Res.rankingTable.records)
{
  "{0} {1} {2} {3} {4} {5} {6} {7} {8} {9} {10} {11}" -f $Item.rankingPosition.ToString().PadLeft(2, " "), $Item.team.name.PadRight(30, " "), `
    "$($Item.played)".PadRight(3, " "), "$($Item.outcomeWon)".PadRight(3, " "), "$($Item.outcomeDrawn)".PadRight(3, " "), "$($Item.outcomeLost)".PadRight(3, " "), `
    "$($Item.pointsFinal)".PadRight(3, " "), "$($Item.goalsFor)".PadRight(3, " "), "$($Item.goalsAgainst)".PadRight(3, " "), "$($Item.goalDifference)".PadRight(3, " "), `
    "$($Item.pointDeducted)".PadRight(3, " "), "$($Item.form -join '')".PadRight(3, " ")
}
