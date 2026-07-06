# build.ps1 - 터블 관리시스템 베이크 빌드
# index.src.html(코드) + data/tubble-data.js(데이터)  ->  index.html(배포용 단일 파일)
#
# 사용법:  이 파일이 있는 폴더에서  ->  powershell -ExecutionPolicy Bypass -File build.ps1
# 배포 전에 이 스크립트 한 번 돌리고 index.html 을 push 하면 됩니다.

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$L1  = [Text.Encoding]::GetEncoding(28591)   # Latin1: 1바이트=1글자, 무손실 처리

$srcPath  = Join-Path $dir 'index.src.html'
$dataPath = Join-Path $dir 'data\tubble-data.js'
$outPath  = Join-Path $dir 'index.html'

if(-not (Test-Path $srcPath))  { throw "index.src.html 없음: $srcPath" }
if(-not (Test-Path $dataPath)) { throw "data/tubble-data.js 없음: $dataPath" }

$src  = [IO.File]::ReadAllText($srcPath,  $L1)
$data = [IO.File]::ReadAllText($dataPath, $L1)

# 코드 안의 로더 태그를, 데이터를 인라인한 스크립트로 교체
$loader  = '<script id="TUBBLE_INJECT" src="data/tubble-data.js"></script>'
$inlined = '<script id="TUBBLE_INJECT">' + $data + '</script>'

$n = ([regex]::Matches($src, [regex]::Escape($loader))).Count
if($n -ne 1){ throw "로더 태그가 정확히 1개가 아님 (발견 $n 개). index.src.html 확인 필요." }

$baked = $src.Replace($loader, $inlined)
[IO.File]::WriteAllText($outPath, $baked, $L1)

$sha = (Get-FileHash $outPath -Algorithm SHA256).Hash
Write-Host ("[OK] 베이크 완료 -> index.html")
Write-Host ("     크기 : {0:N0} bytes ({1:N2} MB)" -f $baked.Length, ($baked.Length/1MB))
Write-Host ("     SHA256: $sha")
