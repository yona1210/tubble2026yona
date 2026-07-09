# split.ps1 - 터블 관리시스템 역-베이크 (배포 index.html -> 코드 + 데이터 분리)
# 인라인 데이터가 박힌 index.html  ->  index.src.html(코드) + data/tubble-data.js(데이터)
#
# 언제 쓰나: 앱에서 데이터를 갱신·export 해 index.html 을 새로 만든 뒤,
#            코드를 편집하기 전에 이걸 돌려서 최신 데이터를 다시 분리해 둡니다.
# 사용법:  powershell -ExecutionPolicy Bypass -File split.ps1

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$L1  = [Text.Encoding]::GetEncoding(28591)   # Latin1: 1바이트=1글자, 무손실

$inPath   = Join-Path $dir 'index.html'
$srcPath  = Join-Path $dir 'index.src.html'
$dataPath = Join-Path $dir 'data\tubble-data.js'

$c = [IO.File]::ReadAllText($inPath, $L1)

$START = '<script id="TUBBLE_INJECT">window.__TUBBLE_DATA__='
$ENDM  = ';</script></head>'
$idxStart = $c.IndexOf($START)
$idxEnd   = $c.IndexOf($ENDM)
if($idxStart -lt 0){ throw "인라인 데이터 시작 마커 못 찾음 — index.html 이 이미 분리형이거나 형식이 다름" }
if($idxEnd   -lt 0){ throw "데이터 끝 마커(;</script></head>) 못 찾음" }

$jsonStart = $idxStart + $START.Length
$jsonText  = $c.Substring($jsonStart, $idxEnd - $jsonStart)   # { ... }

# 데이터 파일
$dataJs = 'window.__TUBBLE_DATA__=' + $jsonText + ';'

# 코드 파일 (데이터 자리에 로더 태그)
$prefix = $c.Substring(0, $idxStart)
$tail   = $c.Substring($idxEnd + ';</script>'.Length)   # '</head>...' 부터
$loader = '<script id="TUBBLE_INJECT" src="data/tubble-data.js"></script>'
$srcHtml = $prefix + $loader + $tail

# 무손실 자체검증: 재조립 == 원본 ?
$rebuilt = $prefix + '<script id="TUBBLE_INJECT">' + $dataJs + '</script>' + $tail
if($rebuilt -cne $c){ throw "자체검증 실패 — 분리 중단(파일 미변경)" }

New-Item -ItemType Directory -Force -Path (Join-Path $dir 'data') | Out-Null
[IO.File]::WriteAllText($dataPath, $dataJs, $L1)
[IO.File]::WriteAllText($srcPath,  $srcHtml, $L1)

Write-Host "[OK] 분리 완료"
Write-Host ("     index.src.html      : {0:N0} bytes" -f $srcHtml.Length)
Write-Host ("     data/tubble-data.js : {0:N0} bytes" -f $dataJs.Length)
