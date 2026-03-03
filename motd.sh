#!/bin/bash
# 功能:动态banner
# 编写日期:2023/02/25
# 编写者:俺

printf "********************************\n"
printf "    ChinaSkills 2022 CSK\n"
printf "      Module C Linux\n"
printf "\n"
printf "        >>%s<<\n" "$(hostname)"
[ -e /etc/redhat-release ] && echo "  >> "$(cat /etc/redhat-release | cut -f 2-4 -d " ")"<<" || printf "\n"
echo ">>"$(date)"<<"
printf "********************************\n"
