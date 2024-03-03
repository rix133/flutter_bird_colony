# Define the first commit
$commit1 = "master"

# Define the default date
$defaultDate = "2023-09-31"

# Check if a date argument was provided
if ($args.Length -eq 0) {
    $date = $defaultDate
} else {
    $date = $args[0]
}

# Get the last commit before a specific date
$commit2 = git rev-list -1 --before="$date" $commit1

# Get the diff stats
$diffStats = git diff --shortstat $commit1 $commit2

# Parse the output
$added_diff = $diffStats -replace '.*?(\d+) insertions.*', '$1'
$changed = $diffStats -replace '.*?(\d+) deletions.*', '$1'

# Get the total number of lines at a specific commit
git checkout -q $commit2
$totalLinesCommit2 = (git ls-files | foreach { Get-Content $_ } | Measure-Object -line).Lines

# Get the total number of lines at the latest commit
git checkout -q $commit1
$totalLinesCommit1 = (git ls-files | foreach { Get-Content $_ } | Measure-Object -line).Lines

#Output comparsion date
Write-Host "Changes since $date" -ForegroundColor Green


# Output the total lines
Write-Output "Total lines at ${date}: $totalLinesCommit2"
Write-Output "Total lines at latest: $totalLinesCommit1"

$added = $totalLinesCommit1 - $totalLinesCommit2

# Calculate percentages
# Calculate percentages
$addedPercent = [Math]::Round(($added / $totalLinesCommit2) * 100)
$changedPercent = [Math]::Round(($changed / $totalLinesCommit2) * 100)

# Calculate the number of unchanged lines
$unchanged = $totalLinesCommit1 - $added - $changed

# Calculate the percentage of unchanged lines
$unchangedPercent = [Math]::Round(($unchanged / $totalLinesCommit1) * 100)

$changedOrAdded = $added + $changed
$changedOrAddedPercent = [Math]::Round(($changedOrAdded / $totalLinesCommit2) * 100)

# Output the results
Write-Output "Percentage of lines added: $addedPercent%"
Write-Output "Percentage of lines changed: $changedPercent%"
Write-Output "Percentage of lines changed or added: $changedOrAddedPercent%"

# Output the percentage of unchanged lines
Write-Output "Percentage of lines unchanged: $unchangedPercent%" -ForegroundColor Green

