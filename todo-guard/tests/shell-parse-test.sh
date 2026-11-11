#!/usr/bin/env bash
# _shell.sh 의 셸 명령 판정(sh_classify) 시험.
#   pre-tool 훅이 「무엇을 바꾸나 · 어디에 쓰나」를 제대로 뽑는지 본다.
#   macOS 기본 bash(3.2) · 윈도우 Git Bash · 리눅스에서 그대로 돈다. 파일을 바꾸지 않는다
#   (빈 임시 폴더를 프로젝트로 삼고, 끝나면 지운다).
#
# 쓰는 법
#   bash ~/.claude/skills/todo-guard/tests/shell-parse-test.sh
#   → 마지막 줄이 「모두 통과」 면 된다. 실패가 있으면 종료 코드 1

HERE="${BASH_SOURCE[0]%/*}"
# 절대 경로로 바꾼다. 아래에서 cd 를 하므로 상대 경로면 그 뒤에 못 찾는다 (2026-11-11)
HERE="$(cd "$HERE" && pwd)"
SCRIPTS="$HERE/../scripts"
[ -f "$SCRIPTS/_shell.sh" ] || SCRIPTS="$HOME/.claude/skills/todo-guard/scripts"

TMPP="${TMPDIR:-/tmp}/tg-shell-test.$$"
mkdir -p "$TMPP/.claude/hooks" || exit 1
trap 'rm -rf "$TMPP"' EXIT
cd "$TMPP" || exit 1

. "$SCRIPTS/_root.sh"
. "$SCRIPTS/_shell.sh"

pass=0; fail=0
# check <모드> <기대 종류> <기대 대상(공백으로 이음)> <명령>
check() {
  local mode="$1" kind="$2" tgt="$3" cmd="$4" got
  sh_classify "$cmd" "$mode"
  got="${SH_TGT[*]}"
  if [ "$SH_KIND" = "$kind" ] && [ "$got" = "$tgt" ]; then
    pass=$((pass+1))
  else
    fail=$((fail+1))
    printf '실패: %s\n  기대: %s [%s]\n  결과: %s [%s]\n' "$cmd" "$kind" "$tgt" "$SH_KIND" "$got"
  fi
}

# 프로세스 치환 · 서브셸 괄호 (2026-11-10 고침: 「)」 가 대상에 붙던 것)
check bash read ''                 "diff <(sed 's/x//' a.md) <(sed 's/y//' b 2>/dev/null) | head -40"
check bash read ''                 'diff <(sort a) <(sort b)'
check bash work '/d/other/out.txt' 'cat <(tee /d/other/out.txt < a)'
check bash work 'build.log'        '(cd sub && make > build.log)'
check bash work '/d/other/x'       '(echo hi > /d/other/x)'
check bash read ''                 '(cd sub && ls 2>/dev/null)'

# 괄호가 있어도 전과 같아야 하는 것
check bash work ''                 'case $x in a) echo ok ;; b) ls ;; esac'
check bash work 'now.txt'          'echo $(date) > now.txt'
check bash work ''                 'for ((i=0;i<3;i++)); do echo $i; done'

# 기본
check bash work 'b'                'cp a b'
check bash work '/d/other/list.txt' 'ls > /d/other/list.txt'
check bash read ''                 'grep foo src 2>/dev/null'
check bash read ''                 'git status'

# 파워셸은 괄호 처리를 바꾸지 않았다
check ps   work 'b'                '(Get-Content a) | Set-Content b'
check ps   read ''                 'Get-ChildItem 2>$null'

echo "bash $BASH_VERSION · 통과 $pass · 실패 $fail"
if [ "$fail" -eq 0 ]; then echo "모두 통과"; exit 0; fi
exit 1
