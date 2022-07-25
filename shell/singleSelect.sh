#!/bin/bash

function singleSelect {
    cursor_blink_on() { printf "\033[?25h"; }       # 显示光标
    cursor_blink_off() { printf "\033[?25l"; }      # 隐藏光标
    cursor_to() { printf "\033[%s;${2:-1}H" "$1"; } # 光标移动到指定行位置
    print_inactive() { printf "%b %b " "$1" "$2"; } # 打印未激活的选项

    # 获取光标所在终端行数
    function get_cursor_row() {
        IFS=';' read -sdRr -p $'\E[6n' ROW _
        echo "${ROW#*[}"
    }

    local return_value=$1
    local -n options=$2
    local selected=()

    for ((i = 0; i < ${#options[@]}; i++)); do
        printf "\n"
    done

    for f in "${selected[@]}"; do
        echo "$f"
    done

    # 确定当前屏幕位置以覆盖选项
    cursor_now_row=$(get_cursor_row)
    local last_row=${cursor_now_row}
    local start_row=$((last_row - ${#options[@]}))

    # 确保在读取 -s 期间在 ctrl+c 上回显光标和输入
    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off

    # 监听按键
    key_input() {
        local key
        IFS= read -rsn1 key 2>/dev/null >&2
        if [[ $key = "" ]]; then echo enter; fi
        if [[ $key = $'\x20' ]]; then echo space; fi
        if [[ $key = $'\x1b' ]]; then
            read -rsn2 key
            if [[ $key = [A || $key = k ]]; then echo up; fi
            if [[ $key = [B || $key = j ]]; then echo down; fi
        fi
    }

    # 设置选项选中状态
    toggle_option() {
        for ((i = 0; i < ${#options[@]}; i++)); do
            if [[ $i = "$1" ]]; then
                selected[$i]=true
            else
                selected[$i]=false
            fi
        done
    }

    # 打印勾选状态选项
    print_options() {
        local idx=0
        for option in "${options[@]}"; do
            local prefix="[ ]"
            if [[ ${selected[idx]} == true ]]; then
                prefix="[\e[38;5;46m>\e[0m]"
            fi

            cursor_to $((start_row + idx))
            print_inactive "$prefix" "$option"
            ((idx++))
        done
    }

    local active=0
    while true; do
        toggle_option "$active"
        print_options $active

        case $(key_input) in
        enter)
            print_options -1
            break
            ;;
        up)
            ((active--))
            toggle_option "$active"
            if [ "$active" -lt 0 ]; then active=$((${#options[@]} - 1)); fi
            ;;
        down)
            ((active++))
            toggle_option "$active"
            if [ "$active" -ge ${#options[@]} ]; then active=0; fi
            ;;
        esac
    done

    # 光标位置恢复正常
    cursor_to "$last_row"
    printf "\n"
    cursor_blink_on

    eval "$return_value"='("${selected[@]}")'
}

#my_options=("v1.1.1" "v1.1.2" "v1.1.3")

#singleSelect result my_options
#singleSelect "$1" "$2"

#idx=0
#for option in "${my_options[@]}"; do
#    echo -e "$option\t=> ${result[idx]}"
#    ((idx++))
#done
