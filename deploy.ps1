# deploy.ps1 - 터블 전체 데이터 원클릭 배포
#   앱에서 '파일 백업 저장'으로 만든 다운로드 폴더의 최신 .json(앱 데이터 전체)을 찾아
#   index.html 에 베이크(bake-json.ps1)하고 git 에 commit + push 합니다.
#   재고뿐 아니라 매출/원가/제조사/기획 등 앱에서 바꾼 모든 데이터가 함께 배포됩니다.
#   사용법: 이 파일(또는 바탕화면 '터블 배포' 바로가기)을 더블클릭.

$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
Set-Location $dir

function PauseExit($code){ Read-Host "`n엔터를 누르면 창이 닫힙니다"; exit $code }

try {
  Write-Host "===== 터블 데이터 배포 (앱 전체) =====" -ForegroundColor Cyan

  # 1) 다운로드 폴더에서 가장 최근 백업 json 찾기
  $dl = Join-Path $env:USERPROFILE 'Downloads'
  $f = Get-ChildItem (Join-Path $dl '터블_관리시스템_*.json') -ErrorAction SilentlyContinue |
       Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if(-not $f){ throw "다운로드 폴더에 '터블_관리시스템_*.json' 백업이 없습니다.`n앱에서 '더보기 > 파일 백업 저장'을 먼저 하세요." }

  # 2) 파일 안의 데이터 날짜(meta.updated) 앞부분만 살짝 읽어 확인
  $fs = [IO.File]::OpenRead($f.FullName)
  $buf = New-Object byte[] 1024
  $n = $fs.Read($buf, 0, 1024); $fs.Close()
  $head = [Text.Encoding]::UTF8.GetString($buf, 0, $n)
  $upd = if($head -match '"updated"\s*:\s*"([^"]+)"'){ $Matches[1] } else { '?' }

  Write-Host ""
  Write-Host ("  파일    : {0}" -f $f.Name)
  Write-Host ("  저장시각 : {0}" -f $f.LastWriteTime)
  Write-Host ("  데이터   : updated = {0}" -f $upd) -ForegroundColor Yellow
  Write-Host ("  크기    : {0:N0} bytes" -f $f.Length)
  Write-Host ""
  $ans = Read-Host "이 파일로 배포할까요?  (Y = 예 / 그 외 아무거나 = 취소)"
  if($ans -ne 'Y' -and $ans -ne 'y'){ Write-Host "취소했습니다." -ForegroundColor Yellow; PauseExit 0 }

  # 3) 베이크 (json -> data/tubble-data.js -> index.html)
  Write-Host "`n[1/3] 베이크 중..." -ForegroundColor Cyan
  & (Join-Path $dir 'bake-json.ps1') $f.FullName

  # 4) 변경이 없으면 종료
  $changed = git status --porcelain -- index.html data/tubble-data.js
  if(-not $changed){ Write-Host "`n변경 사항이 없습니다 (이미 최신입니다)." -ForegroundColor Green; PauseExit 0 }

  # 5) commit + push  (커밋 메시지는 인코딩 안전하게 ASCII 날짜로)
  $d = if($f.Name -match '(\d{4}-\d{2}-\d{2})'){ $Matches[1] } else { 'update' }
  Write-Host "`n[2/3] 커밋 중..." -ForegroundColor Cyan
  git add index.html data/tubble-data.js
  git commit -m ("data update " + $d)
  Write-Host "`n[3/3] 푸시 중... (깃허브 로그인 창이 뜨면 로그인하세요)" -ForegroundColor Cyan
  git push origin main

  Write-Host "`n[완료] 배포되었습니다. GitHub Pages 는 1~2분 내 반영됩니다." -ForegroundColor Green
  Write-Host "       팀원은 새로고침하면 최신본을 봅니다." -ForegroundColor Green
  PauseExit 0
}
catch {
  Write-Host "`n[에러] $($_.Exception.Message)" -ForegroundColor Red
  Write-Host "문제가 계속되면 이 창 내용을 캡처해서 Claude 에게 보여주세요." -ForegroundColor Red
  PauseExit 1
}
