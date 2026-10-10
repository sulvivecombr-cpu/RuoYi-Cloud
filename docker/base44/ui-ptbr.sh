#!/bin/sh
# Brazilian Portuguese console widgets.
#
# The admin UI is a separate project (RuoYi-Cloud-Vue3), cloned into ./ruoyi-ui, and it picks
# the Element Plus locale in src/main.js — hardcoded to zh-cn. Point it at pt-br instead, so
# every Element Plus widget (date pickers, month/week names, pagination, tables, selects,
# dialogs, uploads) speaks Brazilian Portuguese.
#
# compose runs this before the dev server starts, and it is idempotent, so the setting survives
# a fresh clone of the UI. It changes nothing else: the UI project's own page copy is its own
# Chinese source — see AGENTS.md.
#
# Usage: sh docker/base44/ui-ptbr.sh   (run from the UI's working directory)

main=src/main.js
if [ ! -f "$main" ]; then
  echo "ui-ptbr: $main not found - is the UI cloned yet? nothing to do"
  exit 0
fi

if grep -q "element-plus/es/locale/lang/zh-cn" "$main"; then
  sed -i "s#element-plus/es/locale/lang/zh-cn#element-plus/es/locale/lang/pt-br#" "$main"
  echo "ui-ptbr: Element Plus locale -> pt-br"
else
  echo "ui-ptbr: locale line already patched (or upstream changed) - nothing to do"
fi
