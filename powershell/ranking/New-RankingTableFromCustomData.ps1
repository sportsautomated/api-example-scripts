If (-not [String]::IsNullOrEmpty($ApiKey))
{
  $Headers = @{ "X-API-KEY" = $ApiKey }
}
Else 
{
  $Headers = @{}
}

$Uri = "https://api.sportsautomated.com/api/ranking/generate"
$RequestBody = @{
  teams = @()
  matches = @(
    @{ 
      teamHome =  @{ uniqueId = "LIV"; name = "Liverpool FC" } ; teamAway =  @{ uniqueId = "BAY"; name = "FC Bayern Munchen" }
      homeScore = 2; awayScore = "8"; matchState = "Finished"; matchDateTimeUtc="20220529"
    },
    @{
      teamHome = @{ uniqueId = "MC"; name = "Manchester City FC" }; teamAway= @{ uniqueId = "RM"; name = "Real Madrid CF" }
      homeScore = 1; awayScore = 2; matchState = "Finished"; matchDateTimeUtc="20220528"
    },
    @{
      teamHome= @{ uniqueId = "LIV"; name = "Liverpool FC" }; teamAway= @{ uniqueId = "CHE"; name = "Chelsea FC" }
      homeScore = 3; awayScore = 3; matchState = "Finished"; matchDateTimeUtc="20220527"
    },
    @{
      teamHome= @{ uniqueId = "BAY"; name = "FC Bayern Munchen" }; teamAway= @{ uniqueId = "RM"; name = "Real Madrid CF" }
      homeScore = 4; awayScore = 3; matchState= "Finished"; matchDateTimeUtc="20220526"
    },
    @{
      teamHome= @{ uniqueId = "CHE"; name = "Chelsea FC" }; teamAway= @{ uniqueId = "MC"; name = "Manchester City FC" }
      homeScore = 4; awayScore = 4; matchState= "Finished"; matchDateTimeUtc="20220525"
    }
  )
  orderRules = @("OrderByTeamName", "OrderByTotalPoints", "OrderByGoalDifference", "OrderByGoalsFor")
}

$Stopwatch =  [System.Diagnostics.Stopwatch]::StartNew()
$Res = Invoke-RestMethod -Method "POST" -UseBasicParsing -Uri $Uri -Body ($RequestBody | ConvertTo-Json -Compress -Depth 8) -ContentType "application/json" -Headers $Headers
$Stopwatch.Stop()

Clear-Host
"API request took {0} ms for {1} matches" -f $Stopwatch.ElapsedMilliseconds, $RequestBody.matches.Count | Write-Host 
"" | Write-Host

"# {0} GP  W   D   L   P   F   A   GD  PD  FORM" -f "Name".PadRight(30, " ") | Write-Host 
"-".PadRight(75, "-") | Write-Host 
ForEach($Item in $Res.rankingTable.records)
{
  "{0} {1} {2} {3} {4} {5} {6} {7} {8} {9} {10} {11}" -f $Item.rankingPosition, $Item.team.name.PadRight(30, " "), `
    "$($Item.played)".PadRight(3, " "), "$($Item.outcomeWon)".PadRight(3, " "), "$($Item.outcomeDrawn)".PadRight(3, " "), "$($Item.outcomeLost)".PadRight(3, " "), `
    "$($Item.pointsFinal)".PadRight(3, " "), "$($Item.goalsFor)".PadRight(3, " "), "$($Item.goalsAgainst)".PadRight(3, " "), "$($Item.goalDifference)".PadRight(3, " "), `
    "$($Item.pointDeducted)".PadRight(3, " "), "$($Item.form -join '')".PadRight(3, " ")
}
