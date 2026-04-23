# One-Shot Setup Prompt

Claude Code에 아래 프롬프트를 **한 번만** 복사해서 붙여넣으면 설치가 자동 완료됩니다.

> 그대로 복사해서 쓰시면 됩니다. Fork한 본인 저장소를 쓰려면 URL만 바꿔주세요.

---

## 프롬프트 (복사용)

```
TradingView MCP by AI BRIDGE를 설치해줘.

1. 현재 프로젝트 디렉토리 안에 https://github.com/aibridge-leo/tradingview-mcp-aibridge.git 를 clone 해줘 (폴더명: tradingview-mcp-aibridge).
2. 그 디렉토리 안에서 npm install 실행.
3. 프로젝트 루트(현재 cwd)에 .mcp.json 생성:
   {
     "mcpServers": {
       "tradingview": {
         "command": "node",
         "args": ["<clone된 tradingview-mcp-aibridge의 절대경로>/src/server.js"]
       }
     }
   }
   이미 .mcp.json이 있으면 mcpServers 객체에 tradingview 항목만 추가해주고 기존 서버는 보존해줘.
4. tradingview-mcp-aibridge/rules.example.json 을 tradingview-mcp-aibridge/rules.json 으로 복사.
5. 설치 끝나면 아래 순서대로 안내해줘:
   (1) Windows면 tradingview-mcp-aibridge/scripts/launch_tv_debug.bat 더블클릭 (MSIX 경로 자동 탐지)
       Mac이면 scripts/launch_tv_debug_mac.sh, Linux면 scripts/launch_tv_debug_linux.sh 실행
   (2) Claude Code 재시작 (/exit 후 현재 디렉토리에서 claude 재실행)
   (3) /mcp 에서 tradingview: connected 확인
   (4) tv_health_check 실행해서 cdp_connected: true 확인
   (5) 첫 시험: "내 차트 상태 알려줘" 또는 "BTC 김치 프리미엄 알려줘"
```

---

## 프롬프트가 하는 일

1. 현재 작업 중인 프로젝트 디렉토리 안에 MCP 서버 소스를 clone
2. Node 의존성 설치
3. Claude Code가 MCP 서버를 찾을 수 있도록 `.mcp.json` 생성/병합
4. 본인 전략을 담을 `rules.json` 템플릿 복사
5. 사용자가 해야 할 나머지 3단계(실행/재시작/검증)를 안내

## 프롬프트가 하지 않는 일 (사용자가 직접)

- TradingView Desktop 설치 (기존 설치가 있어야 함)
- TradingView 로그인
- **Windows에서 MSIX 설치를 쓰는 경우: 개발자 모드(Developer Mode) ON** — 안 켜져 있으면 CDP 포트가 안 열려 MCP 연결 실패. `설정 → 업데이트 및 보안 → 개발자용 → 개발자 모드: 켬` (Win11은 `개인 정보 보호 및 보안 → 개발자용`). 한 번만 켜두면 됨.
- `rules.json`에 본인 전략 채우기 (선택, 기본 템플릿으로도 동작)
- 실거래 자동화 연결 (별도 설정 필요)

## 설치 후 막히면

- Windows에서 `launch_tv_debug.bat` 더블클릭 시 검은 창이 깜빡이고 닫힘 → 관리자 권한 없는 PowerShell에서 `Get-AppxPackage TradingView.Desktop`이 결과를 반환하는지 먼저 확인
- `/mcp`에 `tradingview`가 안 보임 → `.mcp.json`이 프로젝트 루트에 있는지, 경로가 절대경로인지 확인
- `tv_health_check` 실패 → 포트 9222가 응답하는지: `curl http://localhost:9222/json/version`

자세한 문제 해결은 [SETUP.md](./SETUP.md#troubleshooting) 참고.
