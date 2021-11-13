param (
	[Parameter(Mandatory=$true)][ValidateLength(1, [int32]::MaxValue)][String]$Registry,
	[String]$Tag='latest',
	[switch]$NoCache
)

"Building $Registry/sql-backup:$Tag"
if ($NoCache) {
	docker build -t $Registry/sqlbackup:$Tag --no-cache .\build
}
else {
	docker build -t $Registry/sqlbackup:$Tag .\build
}
if ($LASTEXITCODE -eq 0) {
	""
	"Pushing $Registry/sqlbackup:$Tag"
	docker push $Registry/sqlbackup:$Tag
}
