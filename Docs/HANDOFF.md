# 터블 상품 관리 시스템 — 작업 핸드오프

> VSCode에서 Claude / Codex로 작업을 이어가기 위한 컨텍스트 문서.
> 대상 파일: `터블_관리시스템_v67_보안저장발주연동개선.html` (단일 HTML, ~6,280줄, ~685KB)
> 최종 작업일: 2026-06-24

---

## 1. 이 파일이 무엇인가

터블(Tubble) 브랜드의 **상품 관리 시스템** — 단일 HTML 파일로 동작하는 사내 운영 툴. 빌드 과정 없이 브라우저에서 바로 열림. 외부 라이브러리는 Chart.js를 파일 내부에 인라인 삽입(오프라인 동작 보장).

탭 6개로 구성:

| 탭 | id | 역할 |
|----|----|----|
| 출시 일정 | `tab-launch` | 11단계 공정 관리·간트·주간보고 |
| 재고·발주 | `tab-stock` | 발주 산식·권장 발주수량·매입액 |
| 원가·매입 | `tab-cost` | 차수별 생산원가·묶음 발주·원가율 |
| 시장·전략 | `tab-market` | 경쟁사 조사 |
| 매출 대시보드 | `tab-sales` | 매출 차트(도넛·라인·콤보) |
| 리뷰 분석 | `tab-review` | 평점·감정·구매평 차트 |

---

## 2. 핵심 구조 (라인 번호는 v67 기준, 편집 시 변동됨)

### 전역 상태
- `let DATA` (~1414줄): 전체 데이터 객체. 초기값이 JSON으로 인라인됨
- `const VIEWONLY` / `const EXTERNAL` (1709~1710): 공유본 모드 플래그. `window.__TUBBLE_DATA__`의 `viewonly`/`external`로 결정
- `const STEPS` (1399): 11단계 공정 배열. **순서·개수 변경 금지** (st9/d9 인덱스와 결합)
- `let LEADTIME` (1403): 단계별 리드타임 11개
- `const SHEET_API_URL` (6172): 구글 Apps Script 웹앱 URL **(실제 운영 키 포함 — 외부 노출·커밋 주의)**
- `const SALES_GOAL` (5502): 2026 NB 매출 목표 38.4억

### 데이터 스키마 (DATA 객체)
```
DATA = {
  meta: { title, updated, saved },
  sku: [ { type, nm, br, launch, mfr, round, qty, qtyu, owner, risk, waiting,
           st9: [11단계 상태], d9: [11단계 [시작,종료] 날짜], memo, archived } ],
  stock: [ { nm, cat, ch, msale, stock, lead, cost, moq, price, oem, round,
             stockUnit, orderUnit, unitConversion, orderMultiple,
             inventory: { total, warehouses:{}, ... } } ],
  costDetail: { [품목명]: { rounds:{ "8차":3381, ... "21차":3200 }, qtys:{}, purchase:[[...]], stock:{} } },
  costGroups: [ { id, name, items:[], memo } ],
  stockset: { target, buffer, warn, salesWindow },
  dailyStockHistory: { [품목명]: [ {date, stock, status} ] },
  monthlySalesHistory: { [품목명]: [ {month, qty, source} ] },
  salesData: { ... },   // 매출 탭 업로드 시 생성 (비민감)
  reviewData: { ... },  // 리뷰 탭 업로드 시 생성 (비민감)
  leadtime: [11개]
}
```

### 핵심 함수 위치
| 함수 | 라인 | 역할 |
|------|------|------|
| `getCurrentCost(nm, fallback)` | 1717 | **최신 차수 생산원가** 단일 기준 (rounds 마지막 키) |
| `costNeedsReview(nm)` | 1729 | 최신 원가 없음/0원 판정 → 경고 표시용 |
| `markDirty()` / `markSaved()` | 1714/1715 | 저장상태 토글 |
| `render()` | 2095 | 출시 탭 렌더 |
| `renderStock()` | 2994 | 재고·발주 탭 |
| `renderOrderDecision()` | 3171 | 발주 의사결정 카드 |
| `costMetrics()` | 3330 | 원가 지표 (최신 차수 cur 사용) |
| `renderCost()` | 3628 | 원가 탭 |
| `placeCommonbar(tab)` | 4038 | 공통 파일관리 바를 현재 탭으로 이동 (단일 DOM) |
| `calcStockCoreV47(s,stock,da)` | 5314 | **발주 산식 코어** (매입액·원가율) |
| `calcStock = function(s,opt)` | 5383 | **유효 calcStock** (재할당본) |
| `demandAnalysis = function` | 5274 | **유효 demandAnalysis** (재할당본) |
| `recentSalesMomentum(s,sales)` | 5256 | 상승추세 보정 (최근 2개월 vs 3개월 평균) |
| `parseSalesWorkbook(wb)` | 5577 | 매출 엑셀 파싱 |
| `handleSalesUpload(file)` | 5624 | 매출 업로드 핸들러 |
| `renderSales()` / `drawSalesCharts(sd)` | 5645 / 5683 | 매출 탭 렌더·차트 |
| `parseReviewWorkbook(wb)` | 5866 | 리뷰 엑셀 파싱 |
| `handleReviewUpload(file)` | 5935 | 리뷰 업로드 핸들러 |
| `renderReview()` / `drawReviewCharts(rd)` | 5954 / 5980 | 리뷰 탭 렌더·차트 |
| `loadFromSheet(opts)` | 6175 | 구글시트 불러오기 (VIEWONLY/EXTERNAL 차단됨) |
| `saveToSheet()` | ~6300 | 구글시트 저장 (VIEWONLY/EXTERNAL 차단됨) |
| `exportExternal()` | 2356 | 외부 공유본 생성 (민감데이터 삭제) |

### Chart.js
- `<script id="chartjs-inline">` (866줄): Chart.js 4.4.1 UMD 전체가 인라인. **이 블록은 편집하지 말 것** (압축본)
- 차트 헬퍼: `makeChart`, `chartBox`, `getCurrentCost` 부근의 `CC`(색상 팔레트), `clipLabel`, `lineOrBar`, `centerTextPlugin`

---

## 3. 버전 히스토리 (이번 세션 작업)

### v64 → v65: 매출·리뷰 탭 차트 시각화
- 표·div막대 → Chart.js 도넛·라인·콤보 차트로 교체
- Chart.js 인라인 삽입 (오프라인 동작)
- 기존 데이터 파싱·집계 로직 무변경, 출력(HTML)만 교체
- 표는 삭제 않고 "상세 표 보기" `<details>`로 보존

### v65 → v66: 차트 완성도 보완
- 단일월 데이터 시 라인→막대 폴백 (`lineOrBar`)
- 도넛 범례 잘림 방지 (`clipLabel`, 툴팁엔 원본명)
- 모바일 반응형 (`isNarrow()` → 범례 위치·폰트 조정)
- 도넛 중앙 텍스트 (`centerTextPlugin`): 평점 도넛=평균평점, 감정=총 리뷰수, 매출=누적매출
- KPI 카드 강조: accent 보더, MoM 색상(▲적/▼청), 만족 미니바

### v66 → v67: 보안·저장·발주 연동 (P0~P2)
- **P0-1** 외부 공유본 시트 차단: `loadFromSheet`·`saveToSheet`·자동동기화 실행부에 `if(VIEWONLY‖EXTERNAL) return` 가드
- **P0-2** 업로드 후 `markDirty()`: `handleSalesUpload`·`handleReviewUpload`
- **P1-3** 매출·리뷰 탭 파일관리 바: `placeCommonbar`의 hostMap에 `sales`·`review` 추가
- **P1-4** 최신 원가 발주 연동: `getCurrentCost`/`costNeedsReview` 신설, `calcStockCoreV47`의 매입액·원가율을 최신 차수 기준으로 교체, `editRound`/`addRound`/`delRound` 후 `renderStock()` 재렌더 추가
- **P2** 죽은 `calcStock`·`demandAnalysis` 선언본(구 2493~2617) 삭제

---

## 4. 미완 과제 / 알려진 이슈

### A. demandAnalysis 죽은 재할당 1개 잔존 (P2 미완)
- 현재 `demandAnalysis = function`이 **2곳**(5132 죽은 것, 5274 유효한 것) 존재
- 5132와 5274 **사이에** 유효한 `runoutBasisHtml`·`stockIssues`·`recentSalesMomentum` 재정의가 끼어 있어 단순 블록 삭제 불가
- 실행에는 무해(최종 5274가 이김)하나, "함수 1개만 유지" 원칙 완전 충족하려면 5132 블록만 정밀 제거 필요
- **작업 시 주의**: 5132~(다음 함수 `runoutBasisHtml` 직전)까지만 잘라야 함. 사이 함수 보존 필수

### B. 렌더 검수 미실시
- 작업 환경에 Chromium이 없어 **실제 브라우저 픽셀 렌더 검수 미실시**
- JS 구문·함수 흐름은 jsdom으로 검증했으나, 차트 색상·중앙텍스트 위치·모바일 레이아웃은 실제 데이터로 육안 확인 필요

### C. 검증되지 않은 동작 (실데이터 필요)
- 외부 공유본을 인터넷 환경에서 열어 자동 동기화가 실제 멈추는지
- 원가 차수 수정 후 재고·발주 매입액이 화면에서 즉시 바뀌는지
- 매출/리뷰 엑셀 업로드 시 차트가 의도대로 렌더되는지

---

## 5. 작업 시 반드시 지킬 원칙 (이 프로젝트 고유)

1. **수술적 편집**: 전면 재작성 금지. 해당 함수·블록만 정밀 수정
2. **단일 HTML 유지**: 파일 분리·빌드 도입 금지 (사내 배포 방식이 단일 HTML)
3. **Chart.js 인라인 블록 편집 금지** (866줄 `chartjs-inline`)
4. **STEPS 11단계 순서·개수 불변** (st9/d9 배열 인덱스와 결합)
5. **발주 산식 보존** — 아래 로직은 약화/삭제 금지:
   - 최근 2개월 평균이 3개월 평균보다 15%+ 높으면 상승 보정 (`recentSalesMomentum`)
   - 데일리 정상마감 재고 3건+·7일+ 누적 시 데일리 감소속도 우선
   - 재고 기준 미확정 품목은 공식 발주 차단, 잠정값만 표시
   - MOQ·발주단위 반올림 규칙
   - 월판매 평균은 정수 표시, 내부 산식은 소수점 정밀도 유지
6. **표시광고법**: 미인증 효능 표현 금지 ("제거/분해" → "도움" 수준)
7. **보고서 톤**: 명사형 종결, 모노크롬, 수치 근거 필수

## 6. 검증 방법 (Chromium 없는 환경에서)

```bash
# 1) 구문 검사 — 본문 JS 추출 후 new Function
node -e "위 추출 스크립트로 본문 script 블록 검사"

# 2) jsdom 통합 테스트 (runScripts:'outside-only', Chart 모킹)
#    - DATA에 모의 데이터 주입 후 calcStock/renderSales/renderReview 호출
#    - VIEWONLY/EXTERNAL 시 loadFromSheet/saveToSheet 차단 확인
#    - 차트 ID 1:1 매칭 (chartBox vs makeChart)
```

권장: VSCode에서 Live Server로 실제 렌더 확인 + 실제 엑셀 업로드 테스트.

---

## 7. 다음 작업 우선순위 (제안)

1. **[검수]** 실제 매출·리뷰 엑셀 업로드 → 차트 육안 확인 (B, C 해소)
2. **[P2 마무리]** demandAnalysis 5132 죽은 재할당 정밀 제거 (A)
3. **[기능]** 매출·리뷰 외 탭 추가 시각화 여부 검토
