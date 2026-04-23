# Setup Guide

처음 쓰시는 분을 위한 상세 설치 가이드입니다. One-shot 설치 방법은 [ONE_SHOT_SETUP.md](./ONE_SHOT_SETUP.md) 참고.

## 1. 사전 요구 사항

| 항목 | 최소 버전 | 확인 방법 |
|---|---|---|
| OS | Windows 10+ / macOS 12+ / Linux | — |
| Node.js | 18.x (권장 20+) | `node --version` |
| npm | 9+ | `npm --version` |
| Git | 2.x | `git --version` |
| Claude Code | 최신 | `claude --version` |
| TradingView Desktop | 3.0+ | 앱 실행 후 설정에서 확인 |

### TradingView Desktop 설치

- Windows: [tradingview.com/desktop](https://www.tradingview.com/desktop/) → MSIX 설치 파일 다운로드 → 더블클릭으로 설치. **현재 Microsoft Store를 통한 설치가 기본**입니다.
- macOS: 동일 페이지 → .dmg 다운로드
- Linux: 동일 페이지 → .deb 또는 .AppImage

TradingView 계정은 무료 플랜도 동작하지만, 유료(Pro/Premium) 플랜일수록 동시 지표 수 제한이 완화되어 다수 기능을 활용할 수 있습니다.

### Windows 사전 조건: 개발자 모드(Developer Mode) 필수

Windows에서 TradingView가 MSIX(Microsoft Store) 설치인 경우 — 최근 배포 기본값 — **개발자 모드를 켜야 CDP(`--remote-debugging-port`)가 동작**합니다. MSIX 앱은 개발자 모드가 꺼져 있으면 커맨드 라인 인자가 전달돼도 Electron이 디버그 포트를 열지 않습니다.

켜는 방법:
- Windows 10: **설정 → 업데이트 및 보안 → 개발자용 → 개발자 모드: 켬**
- Windows 11: **설정 → 개인 정보 보호 및 보안 → 개발자용 → 개발자 모드: 켬**

확인 프롬프트가 뜨면 **예(Yes)**. 한 번만 켜두면 됩니다. 클래식 `.exe` 설치(드물게 `%LOCALAPPDATA%\TradingView\`)인 경우에는 불필요합니다.

## 2. 설치

### 옵션 A: One-Shot 프롬프트 (권장)

[ONE_SHOT_SETUP.md](./ONE_SHOT_SETUP.md) 참고.

### 옵션 B: 수동 설치

#### 2.1 Clone

```bash
git clone https://github.com/aibridge-leo/tradingview-mcp-aibridge.git
cd tradingview-mcp-aibridge
npm install
```

#### 2.2 `.mcp.json` 생성

**프로젝트 루트**(Claude Code를 실행하는 디렉토리)에 `.mcp.json`:

```json
{
  "mcpServers": {
    "tradingview": {
      "command": "node",
      "args": ["<절대경로>/tradingview-mcp-aibridge/src/server.js"]
    }
  }
}
```

- Windows 예시: `"C:/Users/leoji/Desktop/Project/2604_AI Trading/tradingview-mcp-aibridge/src/server.js"`
- macOS 예시: `"/Users/leo/projects/tradingview-mcp-aibridge/src/server.js"`

> **중요**: Windows 경로는 역슬래시(`\`) 대신 슬래시(`/`)를 사용하거나, 이스케이프(`\\`)해야 JSON 파싱에 문제없습니다.

#### 2.3 TradingView Desktop을 CDP 모드로 실행

**Windows (MSIX 설치 기본):**

```powershell
.\scripts\launch_tv_debug.bat
```

이 스크립트는 `Get-AppxPackage TradingView.Desktop`으로 설치된 패키지를 탐지한 뒤, Microsoft의 `IApplicationActivationManager` COM API(`AUMID` 기반)로 `--remote-debugging-port=9222` 플래그를 전달하며 실행합니다. `WindowsApps` 폴더의 ACL 제약과 무관하게 동작하고, 버전 업데이트 시에도 재설정 불필요.

> **MSIX는 개발자 모드가 켜져 있어야 합니다.** 스크립트는 시작 시 이 전제를 검사하고, 꺼져 있으면 안내 메시지와 함께 종료합니다. 위의 "Windows 사전 조건" 섹션 참고.
>
> MSIX 콜드 스타트는 느려서(30–60초) 스크립트 타임아웃은 최대 90초로 설정되어 있습니다.

**macOS:**

```bash
./scripts/launch_tv_debug_mac.sh
```

**Linux:**

```bash
./scripts/launch_tv_debug_linux.sh
```

실행 후 `http://localhost:9222/json/version` 응답이 돌아오면 성공.

#### 2.4 Claude Code 재시작

```bash
# 현재 세션 종료
/exit

# 프로젝트 루트로 이동 (.mcp.json이 있는 곳)
cd <프로젝트 루트>

# 재실행
claude
```

첫 실행 시 `.mcp.json`의 신뢰를 묻는 프롬프트가 나올 수 있습니다 → `y`.

#### 2.5 검증

```
/mcp
```
→ `tradingview: connected` 확인

```
tv_health_check 실행해줘
```
→ `cdp_connected: true`, 현재 차트 심볼/타임프레임 표시

## 3. 첫 사용 예시

```
"내 차트 상태 알려줘"
"BTC 4시간 봉으로 봐줘"
"BTC 김치 프리미엄 알려줘"
```

## 4. 트러블슈팅

### `/mcp`에 `tradingview`가 안 보임

- `.mcp.json`이 **프로젝트 루트**에 있는지 확인
- `args` 경로가 **절대경로**인지, **슬래시 방향**이 맞는지 확인
- Claude Code를 완전히 종료 후 재실행했는지 확인 (`--resume` 아닌 새 세션)

### `tv_health_check`가 `cdp_connected: false` 반환

- TradingView Desktop이 CDP 모드로 실행 중인지 확인:

```powershell
Invoke-WebRequest http://localhost:9222/json/version
```

- 실패 시 `scripts/launch_tv_debug.bat` 다시 실행
- 여러 TradingView 창이 떠 있는 경우 모두 종료 후 재실행

### Windows에서 `launch_tv_debug.bat` 더블클릭 시 창이 깜빡이고 사라짐

- PowerShell에서 직접 실행해 로그 확인:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\launch_tv_debug.ps1
```

- `Get-AppxPackage TradingView.Desktop`이 비어있다면 TradingView Desktop이 설치되지 않은 것. MSIX 파일 더블클릭으로 설치 먼저.

### Windows에서 스크립트는 성공했다는데 `/mcp`/`tv_health_check`가 실패

- 대개 개발자 모드가 꺼진 상태. 스크립트가 감지해서 종료하지만, 혹시 우회했다면 `Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' AllowDevelopmentWithoutDevLicense`로 `1`인지 확인
- 한 번 켠 뒤 `scripts\launch_tv_debug.bat` 재실행

### MSIX 아닌 전통 방식(.exe)으로 설치된 경우

드문 케이스. 런처 스크립트가 `$env:LOCALAPPDATA\TradingView\TradingView.exe`, `%ProgramFiles%\TradingView\TradingView.exe` 순으로 폴백합니다. 특정 위치에 수동 설치한 경우:

```powershell
Start-Process "<경로>\TradingView.exe" "--remote-debugging-port=9222"
```

### 포트 9222 충돌

다른 Chromium 기반 앱이 이미 9222를 쓰고 있으면 충돌. 런처에 포트 인자 전달:

```powershell
.\scripts\launch_tv_debug.bat 9333
```

이 경우 `.mcp.json`이나 MCP 서버 설정에서도 포트를 맞춰야 합니다(현재 서버는 9222 하드코딩 — 필요 시 이슈 등록).

### "2 moderate severity vulnerabilities" 경고

`npm install` 후 일부 transitive 의존성의 CVE 경고. 현재 원본 업스트림에서도 동일 경고이며 실제 취약점 영향은 제한적. 보안이 중요한 환경이면 `npm audit fix` 시도.

## 5. 업그레이드

이 fork의 업데이트를 받으려면:

```bash
cd tradingview-mcp-aibridge
git pull
npm install
```

원본 저장소(Jackson fork 또는 tradesdontlie)의 업데이트를 cherry-pick 하려면 이슈/PR로 문의해주세요.

## 6. 삭제

완전 제거:

```bash
# 1. 프로젝트 루트의 .mcp.json에서 tradingview 엔트리 제거
# 2. 서버 디렉토리 삭제
rm -rf tradingview-mcp-aibridge
# 3. Claude Code 재시작
```

TradingView Desktop 자체는 일반적인 앱 제거 방식으로.
