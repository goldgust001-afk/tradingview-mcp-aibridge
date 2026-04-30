# tradingview-mcp-aibridge

**tradingview-mcp by AI BRIDGE** — TradingView Desktop을 Claude Code에 연결하는 MCP 서버. Chrome DevTools Protocol(CDP)을 통해 실행 중인 TradingView 차트를 Claude가 직접 읽고 제어합니다.

### 🇰🇷 한국 트레이더 특화 버전

- ✅ **Windows MSIX 네이티브 지원** — `Get-AppxPackage` 기반 자동 경로 탐지
- ✅ **업비트/빗썸/바이낸스 심볼 기본 제공** — 한국 원화 페어 바로 사용
- ✅ **김치 프리미엄 자동 계산 도구** — `kimchi_premium` 신규 툴
- ✅ 기존 TradingView 제어 도구 전부 포함

---

## 빠른 시작 (One-Shot Setup)

Claude Code에 아래 프롬프트 한 번만 복사-붙여넣기:

```
Set up tradingview-mcp-aibridge for me.
Clone https://github.com/goldgust001-afk/tradingview-mcp-aibridge.git into the current project directory.
Run npm install inside it.
Create .mcp.json in the project root with:
  {
    "mcpServers": {
      "tradingview": {
        "command": "node",
        "args": ["<ABSOLUTE_PATH_TO_CLONED_DIR>/src/server.js"]
      }
    }
  }
Tell me to: (1) launch TradingView with scripts/launch_tv_debug.bat on Windows (auto-detects MSIX install), (2) restart Claude Code, (3) run tv_health_check to verify.
```

> fork해서 본인 버전을 쓰시려면 clone URL을 본인 저장소로 바꿔주세요.

## 사전 요구 사항

- **Windows / macOS / Linux** (Windows MSIX 설치 정식 지원)
- **Node.js 18+**
- **Claude Code** (Pro 플랜 이상 권장)
- **TradingView 계정** (무료도 가능, 유료일수록 지표 등 확장 가능)

## 수동 설치

상세 절차는 [SETUP.md](./SETUP.md) 참고.

## 사용 예시

Claude Code에서 자연어로:

```
"내 차트 상태 알려줘"
→ chart_get_state, data_get_study_values 자동 호출

"BTC 4시간 봉으로 봐줘"
→ chart_set_symbol, chart_set_timeframe

"BTC 김치 프리미엄 알려줘"             ← AI BRIDGE 추가
→ kimchi_premium (UPBIT:BTCKRW, BINANCE:BTCUSDT, USD/KRW 자동 비교)

"이 Pine Script 버그 찾아 고쳐줘"
→ pine_get_source, pine_set_source, pine_smart_compile
```

## 주요 기능

| 카테고리 | 도구 예시 |
|---|---|
| **차트 읽기** | `chart_get_state`, `data_get_study_values`, `quote_get`, `data_get_ohlcv` |
| **차트 조작** | `chart_set_symbol`, `chart_set_timeframe`, `chart_manage_indicator` |
| **Pine Script** | `pine_set_source`, `pine_smart_compile`, `pine_get_errors` |
| **드로잉** | `draw_shape`, `draw_list`, `draw_clear` |
| **Replay** | `replay_start`, `replay_step`, `replay_trade`, `replay_status` |
| **알림** | `alert_create`, `alert_list`, `alert_delete` |
| **배치** | `batch_run` (여러 심볼 × 타임프레임 일괄) |
| **🇰🇷 한국 특화** | `kimchi_premium` (김치 프리미엄 계산) |

전체 목록 및 도구 선택 가이드는 [CLAUDE.md](./CLAUDE.md) 참고.

## 한국 트레이더 기본 설정

### 심볼 표기

| 자산 | 업비트 | 빗썸 | 바이낸스 |
|---|---|---|---|
| 비트코인 | `UPBIT:BTCKRW` | `BITHUMB:BTCKRW` | `BINANCE:BTCUSDT` |
| 이더리움 | `UPBIT:ETHKRW` | `BITHUMB:ETHKRW` | `BINANCE:ETHUSDT` |
| 솔라나 | `UPBIT:SOLKRW` | `BITHUMB:SOLKRW` | `BINANCE:SOLUSDT` |

## 프로젝트 구조

```
tradingview-mcp-aibridge/
├── src/
│   ├── server.js            # MCP 서버 엔트리
│   ├── core/                # CDP 클라이언트 + 도구 로직
│   │   └── korean.js        # 🇰🇷 김치 프리미엄 계산
│   ├── tools/               # MCP 도구 래퍼
│   │   └── korean.js        # 🇰🇷 kimchi_premium 툴
│   └── cli/                 # `tv` CLI
├── scripts/
│   ├── launch_tv_debug.bat  # Windows MSIX 자동 탐지 런처
│   └── launch_tv_debug.ps1  # 런처 로직 (PowerShell)
├── agents/                  # Claude Code 서브 에이전트
├── skills/                  # 워크플로 스킬
├── CLAUDE.md                # 도구 선택 가이드 (Claude가 자동 로드)
├── SETUP.md                 # 상세 설치 가이드
├── package.json
├── LICENSE
└── README.md                # 이 파일
```

## 주의 사항

- 본 프로젝트는 **비공식 도구**로, TradingView Inc. 및 Anthropic PBC와 제휴 관계가 없습니다.
- CDP 기반 데스크탑 자동화는 TradingView 약관에 명시적으로 허용되지 않은 영역입니다. 주 계정보다 **테스트 계정 사용을 권장**합니다.
- 실거래 자동화(웹훅 등) 연결 전 반드시 **소액으로 검증**하세요.
- 사용자는 본인의 사용이 TradingView 약관 및 관련 법규를 준수하는지 확인할 책임이 있습니다.

## Credits

이 프로젝트는 아래 오픈소스 프로젝트 위에 쌓아 올렸습니다.

- 원본: [tradesdontlie/tradingview-mcp](https://github.com/tradesdontlie/tradingview-mcp) — TradingView Desktop ↔ Claude Code 연결의 기초를 만든 프로젝트
- 바로 앞 fork: [LewisWJackson/tradingview-mcp-jackson](https://github.com/LewisWJackson/tradingview-mcp-jackson) — one-shot setup 구조 추가

AI BRIDGE fork가 추가한 것:
- Windows MSIX 환경 네이티브 지원 (`Get-AppxPackage` 기반 런처)
- `kimchi_premium` 툴 (업비트 ↔ 바이낸스 ↔ USD/KRW 자동 계산)
- 한국어 문서화

## 라이선스

MIT License. 자세한 내용은 [LICENSE](./LICENSE) 참고.

- Copyright (c) 2026 tradesdontlie (원본 저작자)
- Copyright (c) 2026 AI BRIDGE (본 fork의 수정분)

## 기여

이슈/PR 환영합니다. 버그 리포트 시 Windows 버전, TradingView Desktop 버전, Node.js 버전을 포함해 주세요.
