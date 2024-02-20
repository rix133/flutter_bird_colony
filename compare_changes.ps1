# Define the two commits
$commit1 = "master"
$commit2 = "264e602cfb94573ab766d28a5aa23cb0a7fc5126"

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

# Output the total lines
Write-Output "Total lines at commit ${commit2}: $totalLinesCommit2"
Write-Output "Total lines at commit ${commit1}: $totalLinesCommit1"
$added = $totalLinesCommit1 - $totalLinesCommit2

# Calculate percentages
$addedPercent = [Math]::Round(($added / $totalLinesCommit2) * 100)
$changedPercent = [Math]::Round(($changed / $totalLinesCommit2) * 100)
$changedOrAdded = $added + $changed 
$changedOrAddedPercent = [Math]::Round(($changedOrAdded / $totalLinesCommit2) * 100)

# Output the results
Write-Output "Percentage of lines added: $addedPercent%"
Write-Output "Percentage of lines changed: $changedPercent%"
Write-Output "Percentage of lines changed or added: $changedOrAddedPercent%"

#color the last output
Write-Host "Overall changes: $changedOrAddedPercent%" -ForegroundColor Green




