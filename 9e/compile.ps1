function WriteLuaScriptToJsonContent([int]$jsonLineNumber, [int]$luaScriptFileIdx)
{
    $fileName = ('{0}{1}' -f $pathLua, $luaScriptFiles[$luaScriptFileIdx])
    $luaContent = (Get-Content $fileName)
    $stringObj = Out-String -inputobject $luaContent
    $stringObj = ($stringObj | ConvertTo-Json)
    $luaScriptTag = "${stringObj}"
    $curJsonContentOnLine = $jsonContent[$jsonLineNumber]
    Write-Host "Writing to JSON LineNumber ${jsonLineNumber}. " -NoNewLine
    $curJsonContentOnLine = $curJsonContentOnLine -replace ".{3}$"
    $jsonContent[$jsonLineNumber] = "${curJsonContentOnLine}${luaScriptTag}"
    $jsonContent[$jsonLineNumber] += ','
}

$pathLua = '.\TTSLUA\'
$pathJson = '.\TTSJSON\ftc_base_v2.33'
$jsonExt = '.json'
$jsonCompileUpdate = '_compiled'
$regexLuaGUID = '-- FTC-GUID: (.*)'
$regexJsonGUID = '["]GUID["]: ["](.*)["]'
$regexJsonLuaScript = '["]LuaScript["]: '
$luaScriptFiles = @('global.ttslua', '3SearchAndDestroy.ttslua', '9eScoreSheet.ttslua', '40kItems.ttslua', 'armyPlacer.ttslua', 'automacPsykicDeckBox.ttslua',
    'automacTokenBagsBox.ttslua', 'blankObjectiveCard.ttslua', 'blueDiceTable.ttslua', 'blueHiddenZone.ttslua', 'blueKustom40kDiceRollerMk3.ttslua',
    'bluePsykicPowers.ttslua', 'blueTokens.ttslua', 'blueTurns.ttslua', 'ch1ScreenH.ttslua', 'ch2ScreenH.ttslua', 'ch6ScreenH.ttslua',
    'clock.ttslua', 'customTile1.ttslua', 'customTile2.ttslua', 'customTile3.ttslua', 'customTile4.ttslua', 'customTile5.ttslua', 'customTile6.ttslua',
    'customToken1.ttslua', 'customToken2.ttslua', 'customToken3.ttslua', 'customToken4.ttslua', 'customToken5.ttslua', 'extractTerrain.ttslua',
    'flexTableControl.ttslua', 'gameRounds.ttslua', 'instructions.ttslua', 'ktItems.ttslua', 'matObjSurface.ttslua', 'matUrl.ttslua',
    'redDiceTable.ttslua', 'redHiddenZone.ttslua', 'redKustom40kDiceRollerMk3.ttslua', 'redPsykicPowers.ttslua', 'redTokens.ttslua', 'redTurns.ttslua',
    'secondaryObjectivesManagerBlue.ttslua', 'secondaryObjectivesManagerRed.ttslua', 'spawnGameTools.ttslua', 'squadActivation.ttslua', 'squadActivationBlue.ttslua',
    'squadActivationRed.ttslua', 'startMenu.ttslua', 'timer.ttslua', 'woundsRemaining.ttslua', 'woundsRemainingBlue.ttslua', 'woundsRemainingRed.ttslua')
# test to see if the json file exists
$fileName = ('{0}{1}' -f $pathJson, $jsonExt)
if(!(Test-Path $fileName))
{
    echo "${fileName} could not be found! Ending compilation..."
}

$luaContent = ''
$processEcho = ''
$luaGUID = @()
# pull each of the GUIDs and store them, ignore the first lua file as it's the global file with no GUID
for($luaIdx = 1; $luaIdx -lt $luaScriptFiles.Count; $luaIdx++)
{
    # test if the lua script file does exists
    $fileName = ('{0}{1}' -f $pathLua, $luaScriptFiles[$luaIdx])
    if(!(Test-Path $fileName))
    {
        echo "${fileName} could not be found! Ending compilation..."
        pause
        exit
    }
    
    # grab the contents of the lua script file and capture the GUID from the first line
    Write-Host "Searching for GUID in ${fileName}..." -NoNewLine
    $luaContent = (Get-Content $fileName)
    $luaGUID += ($luaContent[0] | Select-String $regexLuaGUID)
    # test to see if we received a valid GUID
    if($luaGUID[$luaIdx - 1] -eq 0)
    {
        Write-Host "No GUID found! Ending compilation..."
        pause
        exit
    }

    if($luaGUID.Matches[$luaIdx - 1].Groups[1].Value -eq "")
    {
        Write-Host "No GUID found! Ending compilation..."
        pause
        exit
    }
    
    $guidStr = $luaGUID.Matches[$luaIdx - 1].Groups[1].Value
    Write-Host "GUID ${guidStr} found."
}


# grab the contents of the json file
$fileName = ('{0}{1}' -f $pathJson, $jsonExt)
$luaGUIDCount = $luaGUID.Count
Write-Host "${luaGUIDCount} GUIDs have been found!"
Write-Host "Searching GUIDs in ${fileName}..."
$jsonContent = Get-Content ('{0}' -f $fileName)
$lineNum = 0
$jsonGUID = ''
$GUIDfound = 'False'
# find each line that contains a GUID and LuaScript in the json file
# there will be one more LuaScript line than GUID as this is the global LuaScript
$jsonGUIDLine = ($jsonContent | Select-String $regexJsonGUID)
$jsonLuaScriptLine = ($jsonContent | Select-String $regexJsonLuaScript)
# update the json content with the global LuaScript content
$lineNum = $jsonLuaScriptLine[0].LineNumber - 1
Write-Host 'Locating Global LuaScript in JSON...' -NoNewLine
WriteLuaScriptToJsonContent $lineNum 0
Write-Host 'Successful update.'
# iterate through the lua script GUIDs
for($idx = 0; $idx -lt $luaGUID.Count; $idx++)
{
    $num = $idx + 1
    $numOf = $luaGUID.Count
    $findGUID = $luaGUID.Matches[$idx].Groups[1].Value
    Write-Host "Locating GUID ${findGUID} ${num} out of ${numOf}..." -NoNewLine
    # check against the list of GUIDs from the json file
    for($jsonGUIDIdx = 0; $jsonGUIDIdx -lt $jsonGUIDLine.Count; $jsonGUIDIdx++)
    {
        $jsonGUID = $jsonGUIDLine.Matches[$jsonGUIDIdx].Groups[1].Value
        # match the json GUID with the lua script GUID then modify json content 
        if($findGUID -eq $jsonGUID)
        {
            $lineNum = $jsonLuaScriptLine[$jsonGUIDIdx + 1].LineNumber - 1
            Write-Host 'GUID found! ' -NoNewLine
            WriteLuaScriptToJsonContent $lineNum ($idx + 1)
            $GUIDfound = 'True'
            Write-Host 'Successful update!'
            $jsonGUIDIdx = $jsonGUIDLine.Count
        }
    }
    
    # stop if no GUID match was found
    if($GUIDfound -eq 'False')
    {
        Write-Host 'GUID not found! Ending compilation...'
        pause
        exit
    }
    $GUIDfound = 'False'
}
# write out the content to a new file
$fileName = ('{0}{1}{2}' -f $pathJson, $jsonCompileUpdate, $jsonExt)
$jsonContent | Set-Content('{0}' -f $fileName)
pause