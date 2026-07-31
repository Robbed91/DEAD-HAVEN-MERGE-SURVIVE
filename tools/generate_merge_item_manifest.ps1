$repoRoot = Split-Path -Parent $PSScriptRoot
$itemRoot = Join-Path $repoRoot 'data/items'
$questRoot = Join-Path $repoRoot 'data/quests'
$outputPath = Join-Path $repoRoot 'docs/MERGE_ITEM_ASSET_MANIFEST.csv'
$rarities = @('Common', 'Uncommon', 'Rare', 'Story')
$chainNames = @{
    construction = 'Construction'; tool = 'Tools'; food = 'Food'; medical = 'Medical'; trap = 'Traps'
    fuel = 'Fuel'; vehicle_parts = 'Vehicle parts'; electronics = 'Electronics'; clothing = 'Clothing and armour'
    energy_reward = 'Energy'; coin_reward = 'Coins and currencies'; token_reward = 'Coins and currencies'; xp_reward = 'Coins and currencies'
}

function Read-Field([string]$content, [string]$field, [string]$fallback = '') {
    $match = [regex]::Match($content, "(?m)^$([regex]::Escape($field)) = `"([^`"]*)`"")
    if ($match.Success) { return $match.Groups[1].Value }
    return $fallback
}

$questTexts = @{}
Get-ChildItem -LiteralPath $questRoot -Filter '*.tres' | ForEach-Object { $questTexts[$_.BaseName] = Get-Content -LiteralPath $_.FullName -Raw }
$allReferenceFiles = Get-ChildItem -LiteralPath (Join-Path $repoRoot 'data') -Recurse -File | Where-Object Extension -in '.tres', '.gd'
$allReferenceFiles += Get-ChildItem -LiteralPath (Join-Path $repoRoot 'scenes') -Recurse -File | Where-Object Extension -in '.tres', '.gd'

$definitions = @()
foreach ($file in (Get-ChildItem -LiteralPath $itemRoot -Filter '*.tres' | Sort-Object Name)) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    $id = Read-Field $content 'id'
    $chainId = Read-Field $content 'chain_id'
    $iconPath = Read-Field $content 'icon_path'
    $levelMatch = [regex]::Match($content, '(?m)^level = (\d+)')
    $rarityMatch = [regex]::Match($content, '(?m)^rarity = (\d+)')
    $producerMatch = [regex]::Match($content, '(?m)^is_producer = (true|false)')
    $definitions += [PSCustomObject]@{
        Id = $id
        Name = Read-Field $content 'display_name'
        ChainId = $chainId
        Chain = if ($chainNames.ContainsKey($chainId)) { $chainNames[$chainId] } else { $chainId }
        Level = if ($levelMatch.Success) { [int]$levelMatch.Groups[1].Value } else { 1 }
        Rarity = if ($rarityMatch.Success) { $rarities[[int]$rarityMatch.Groups[1].Value] } else { 'Common' }
        IconPath = $iconPath
        IsProducer = $producerMatch.Success -and $producerMatch.Groups[1].Value -eq 'true'
        Produces = Read-Field $content 'produces_item_id'
    }
}

$producersByChain = @{}
foreach ($definition in $definitions | Where-Object IsProducer) { $producersByChain[$definition.ChainId] = $definition.Id }

$rows = foreach ($definition in $definitions) {
    $tasks = @()
    foreach ($entry in $questTexts.GetEnumerator()) {
        if ($entry.Value -match "(?m)^requirements = \{[\s\S]*?`"$([regex]::Escape($definition.Id))`"\s*:") { $tasks += $entry.Key }
    }
    $references = @()
    foreach ($referenceFile in $allReferenceFiles) {
        if ($referenceFile.FullName -like "$itemRoot*") { continue }
        $text = Get-Content -LiteralPath $referenceFile.FullName -Raw
        if ($text.Contains('"' + $definition.Id + '"')) {
            $relative = $referenceFile.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
            $references += $relative
        }
    }
    $producerSource = if ($definition.IsProducer) {
        "Starter producer; produces $($definition.Produces)"
    } elseif ($producersByChain.ContainsKey($definition.ChainId)) {
        $producersByChain[$definition.ChainId]
    } elseif ($definition.ChainId.EndsWith('_reward')) {
        'Reward/scavenging grants; collected from board'
    } else {
        'No implemented producer source'
    }
    $diskPath = if ($definition.IconPath.StartsWith('res://')) { Join-Path $repoRoot $definition.IconPath.Substring(6).Replace('/', '\') } else { '' }
    $exists = -not [string]::IsNullOrWhiteSpace($diskPath) -and (Test-Path -LiteralPath $diskPath)
    $status = if ($exists) { 'Final integrated' } else { 'Missing PNG; procedural placeholder fallback active' }
    [PSCustomObject][ordered]@{
        'Item ID' = $definition.Id
        'Item name' = $definition.Name
        'Chain' = $definition.Chain
        'Chain ID' = $definition.ChainId
        'Level' = $definition.Level
        'Rarity' = $definition.Rarity
        'Current placeholder path' = $definition.IconPath
        'Required final filename' = $definition.IconPath
        'Required dimensions' = '256x256 RGBA PNG; subject within shared 210x210 safe area; high-resolution source retained'
        'Transparency requirements' = 'Transparent corners/background; soft contact shadow retained; no matte fringe'
        'Producer source' = $producerSource
        'Tasks using the item' = ($tasks | Sort-Object) -join '; '
        'Other implemented consumers' = ($references | Sort-Object -Unique) -join '; '
        'Integration status' = $status
    }
}

$rows | Export-Csv -LiteralPath $outputPath -NoTypeInformation -Encoding UTF8
Write-Output "MERGE_ITEM_MANIFEST_WRITTEN rows=$($rows.Count) path=$outputPath"
