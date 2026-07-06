param(
  [Parameter(Mandatory=$true)][string]$Json   # 반영할 .json 백업 파일 경로
)
# bake-json.ps1 - 앱 백업(.json)을 데이터로 반영 후 배포용 index.html 베이크
#   .json  ->  data/tubble-data.js  ->  (build.ps1)  ->  index.html
# 사용법:  powershell -ExecutionPolicy Bypass -File bake-json.ps1 "C:\...\터블_관리시스템_YYYY-MM-DD.json"

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$L1  = [Text.Encoding]::GetEncoding(28591)   # 1바이트=1글자, 무손실

if(-not (Test-Path $Json)){ throw ".json 없음: $Json" }
$j = ([IO.File]::ReadAllText($Json, $L1)).Trim()

# 최소 형식 검증
if($j[0] -ne '{' -or $j[$j.Length-1] -ne '}'){ throw "JSON 형식 이상(‘{’로 시작하고 ‘}’로 끝나야 함)" }

# HTML 안전: 데이터 텍스트의 </script 를 <\/script 로 (스크립트 조기종료 방지, JSON 의미 동일)
$escaped = $j.Replace('</script','<\/script')
if($escaped.Length -ne $j.Length){ Write-Host "  * </script 이스케이프 적용됨" }

# 라이브 배포는 편집 가능해야 하므로 최상위 viewonly:false 보장
$before = $escaped
$escaped = $escaped -replace '"viewonly":\s*true','"viewonly":false'
if($escaped -ne $before){ Write-Host "  * viewonly:true -> false 로 강제(라이브 배포)" }

# data/tubble-data.js 작성
$dataJs = 'window.__TUBBLE_DATA__=' + $escaped + ';'
New-Item -ItemType Directory -Force -Path (Join-Path $dir 'data') | Out-Null
[IO.File]::WriteAllText((Join-Path $dir 'data\tubble-data.js'), $dataJs, $L1)
Write-Host ("[OK] data/tubble-data.js 갱신 : {0:N0} bytes" -f $dataJs.Length)

# 베이크
& (Join-Path $dir 'build.ps1')
