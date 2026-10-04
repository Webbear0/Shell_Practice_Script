#!/bin/bash
# 功能:动态banner
# 编写日期:2023/02/25

printf "********************************\n"
printf "            你好:%s\n" "$(whoami)"
printf "\n"
printf "        >>%s<<\n" "$(hostname)"
echo ">>"$(date)"<<"
printf "********************************\n"