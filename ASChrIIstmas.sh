#!/usr/bin/env bash
# ==============================================================================
#  aschristmas.sh - Detailed Large Blocky Christmas Tree & ANSI Shadow Text
# ==============================================================================

export LC_ALL=C.UTF-8 2>/dev/null || true
shopt -s extglob

TERM_COLS=130
TERM_ROWS=34
LAST_COLS=0
LEFT_W=47
RIGHT_COL=49
RIGHT_W=81
CUR_R=1
CUR_C=1
TREE_BASE_C=2
TICK=0
POOL_SIZE=48
declare -a SNOW_POOL
GROUND_SNOW=""
FRAME_BUF=""
BLK_CH=" "
BLK_LN=1
ROW_PART=""
CHAR_W=0
CLEAN_NUM=0
SELECTED_MODE=""
GREETING_LANG="HU"
COUNTDOWN_TOTAL=60
TARGET_TS=0

init_snow_pool() {
    local p=0
    local c=1
    local seed=0
    local line_buf=""
    while (( p < POOL_SIZE )); do
        line_buf=""
        c=1
        while (( c <= TERM_COLS )); do
            seed=$(( (c * 37 + p * 13 + 1000) % 97 ))
            if (( seed == 0 )); then
                line_buf+="\033[1;37m*\033[0m"
            elif (( seed == 1 )); then
                line_buf+="\033[37m.\033[0m"
            elif (( seed == 2 )); then
                line_buf+="\033[2;36m+\033[0m"
            else
                line_buf+=" "
            fi
            c=$(( c + 1 ))
        done
        SNOW_POOL[p]="$line_buf"
        p=$(( p + 1 ))
    done

    GROUND_SNOW=""
    c=1
    while (( c <= TERM_COLS )); do
        if (( (c * 7) % 5 == 0 )); then
            GROUND_SNOW+="^"
        elif (( c % 2 == 0 )); then
            GROUND_SNOW+="~"
        else
            GROUND_SNOW+="_"
        fi
        c=$(( c + 1 ))
    done
}

update_layout() {
    TERM_COLS=$(tput cols 2>/dev/null || echo 130)
    TERM_ROWS=$(tput lines 2>/dev/null || echo 34)
    if (( TERM_COLS < 90 )); then
        TERM_COLS=90
    fi
    if (( TERM_ROWS < 32 )); then
        TERM_ROWS=32
    fi
    LEFT_W=$(( TERM_COLS * 38 / 100 ))
    if (( LEFT_W < 46 )); then
        LEFT_W=46
    fi
    RIGHT_COL=$(( LEFT_W + 2 ))
    RIGHT_W=$(( TERM_COLS - RIGHT_COL ))
    if (( TERM_COLS != LAST_COLS )); then
        init_snow_pool
        LAST_COLS="$TERM_COLS"
    fi
}

cleanup() {
    tput cnorm 2>/dev/null || printf '\033[?25h'
    tput rmcup 2>/dev/null || true
    printf '\033[0m\n'
    exit 0
}

trap cleanup INT TERM
trap 'LAST_COLS=0' WINCH

move_cursor() {
    printf '\033[%d;' "$CUR_R"
    printf '%dH' "$CUR_C"
}

buf_move() {
    local seq_r=""
    local seq_c=""
    printf -v seq_r '\033[%d;' "$CUR_R"
    printf -v seq_c '%dH' "$CUR_C"
    FRAME_BUF+="$seq_r"
    FRAME_BUF+="$seq_c"
}

draw_snow() {
    local r=1
    local idx=0
    local shift=$(( TICK % POOL_SIZE ))
    while (( r < TERM_ROWS )); do
        idx=$(( (r - shift + POOL_SIZE) % POOL_SIZE ))
        CUR_R="$r"
        CUR_C=1
        buf_move
        FRAME_BUF+="${SNOW_POOL[idx]}"
        r=$(( r + 1 ))
    done
    CUR_R="$TERM_ROWS"
    CUR_C=1
    buf_move
    FRAME_BUF+="\033[1;37m"
    FRAME_BUF+="$GROUND_SNOW"
    FRAME_BUF+="\033[0m"
}

tree_part() {
    local offset="$1"
    local content="$2"
    CUR_C=$(( TREE_BASE_C + offset ))
    buf_move
    FRAME_BUF+="$content"
}

tree_segment() {
    local seg_off="$1"
    local seg_txt="$2"
    CUR_C=$(( TREE_BASE_C + seg_off ))
    buf_move
    FRAME_BUF+="$seg_txt"
    CUR_R=$(( CUR_R + 1 ))
}

# Large 43x31 Solid Blocky Christmas Tree (no interior half-block holes) + Animated Star
draw_tree() {
    local tree_width=43
    local tree_height=31

    TREE_BASE_C=$(( (LEFT_W - tree_width) / 2 + 1 ))
    if (( TREE_BASE_C < 2 )); then
        TREE_BASE_C=2
    fi

    CUR_R=$(( (TERM_ROWS - tree_height) / 2 + 1 ))
    if (( CUR_R < 1 )); then
        CUR_R=1
    fi

    local star_frame=$(( TICK % 4 ))
    case "$star_frame" in
        0)
            tree_segment 21 '\033[1;33m█\033[0m'
            tree_part 18 '\033[33m▄\033[0m'
            tree_part 21 '\033[1;37m█\033[0m'
            tree_segment 24 '\033[33m▄\033[0m'
            tree_segment 15 '\033[33m▄▄\033[1;33m███\033[1;37m███\033[1;33m███\033[33m▄▄\033[0m'
            tree_segment 19 '\033[1;33m▀█\033[1;37m█\033[1;33m█▀\033[0m'
            tree_part 18 '\033[33m▀\033[0m'
            tree_part 21 '\033[1;33m█\033[0m'
            tree_segment 24 '\033[33m▀\033[0m'
            ;;
        1)
            tree_part 17 '\033[1;33m▄\033[0m'
            tree_part 21 '\033[1;37m█\033[0m'
            tree_segment 25 '\033[1;33m▄\033[0m'
            tree_segment 19 '\033[1;33m█\033[1;37m███\033[1;33m█\033[0m'
            tree_segment 14 '\033[1;37m▄\033[1;33m████\033[1;37m█████\033[1;33m████\033[1;37m▄\033[0m'
            tree_segment 19 '\033[1;33m█\033[1;37m███\033[1;33m█\033[0m'
            tree_part 17 '\033[1;33m▀\033[0m'
            tree_part 21 '\033[1;33m█\033[0m'
            tree_segment 25 '\033[1;33m▀\033[0m'
            ;;
        2)
            tree_part 16 '\033[33m█\033[0m'
            tree_part 21 '\033[1;33m█\033[0m'
            tree_segment 26 '\033[33m█\033[0m'
            tree_segment 18 '\033[1;37m▄\033[1;33m█████\033[1;37m▄\033[0m'
            tree_segment 16 '\033[33m██\033[1;33m██\033[1;37m███\033[1;33m██\033[33m██\033[0m'
            tree_segment 18 '\033[1;37m▀\033[1;33m█████\033[1;37m▀\033[0m'
            tree_part 16 '\033[33m▀\033[0m'
            tree_part 21 '\033[1;33m█\033[0m'
            tree_segment 26 '\033[33m▀\033[0m'
            ;;
        3)
            tree_segment 21 '\033[1;37m█\033[0m'
            tree_part 17 '\033[1;33m█\033[0m'
            tree_part 20 '\033[1;37m███\033[0m'
            tree_segment 25 '\033[1;33m█\033[0m'
            tree_segment 15 '\033[33m▄\033[1;33m███\033[1;37m█████\033[1;33m███\033[33m▄\033[0m'
            tree_part 17 '\033[1;33m█\033[0m'
            tree_part 20 '\033[1;37m███\033[0m'
            tree_segment 25 '\033[1;33m█\033[0m'
            tree_segment 21 '\033[1;33m█\033[0m'
            ;;
    esac

    # Tier 1 (Top Crown - solid full blocks inside)
    tree_segment 20 '\033[32m▄\033[1;32m█\033[32m▄\033[0m'
    tree_segment 18 '\033[32m▄█\033[1;32m█\033[1;31m█\033[1;32m█\033[32m█▄\033[0m'
    tree_segment 16 '\033[32m▄██\033[1;33m█\033[1;32m███\033[1;36m█\033[32m██▄\033[0m'
    tree_segment 14 '\033[1;37m▀\033[32m██\033[1;35m█\033[32m██\033[1;33m██\033[1;32m██\033[1;31m█\033[32m███\033[1;37m▀\033[0m'

    # Tier 2 (Upper-Mid Boughs - solid full blocks inside)
    tree_segment 17 '\033[32m▄█\033[1;32m██\033[1;36m█\033[1;32m██\033[32m█▄\033[0m'
    tree_segment 15 '\033[32m▄██\033[1;31m█\033[1;32m███\033[32m██\033[1;33m█\033[32m██▄\033[0m'
    tree_segment 13 '\033[32m▄██\033[1;33m█\033[32m██\033[1;35m█\033[1;32m███\033[32m██\033[1;36m█\033[32m███▄\033[0m'
    tree_segment 11 '\033[1;37m▀\033[32m███\033[1;36m█\033[32m██\033[1;33m██\033[1;32m███\033[1;31m█\033[32m██\033[1;35m█\033[32m████\033[1;37m▀\033[0m'

    # Tier 3 (Middle Boughs - solid full blocks inside)
    tree_segment 14 '\033[32m▄██\033[1;32m██\033[1;31m█\033[32m███\033[1;33m█\033[1;32m██\033[32m██▄\033[0m'
    tree_segment 12 '\033[32m▄███\033[1;35m█\033[1;32m███\033[32m██\033[1;36m█\033[1;32m███\033[1;31m█\033[32m███▄\033[0m'
    tree_segment 10 '\033[32m▄███\033[1;33m██\033[32m██\033[1;36m█\033[1;32m████\033[32m██\033[1;35m█\033[32m██\033[1;33m█\033[32m███▄\033[0m'
    tree_segment 8  '\033[1;37m▀\033[32m████\033[1;31m█\033[32m███\033[1;33m██\033[1;32m███\033[1;37m█\033[32m███\033[1;33m██\033[32m██\033[1;36m█\033[32m███\033[1;37m▀\033[0m'

    # Tier 4 (Lower-Mid Boughs - solid full blocks inside)
    tree_segment 12 '\033[32m▄███\033[1;36m█\033[1;32m███\033[32m███\033[1;35m█\033[1;32m███\033[1;33m█\033[32m██▄\033[0m'
    tree_segment 10 '\033[32m▄███\033[1;32m██\033[1;31m█\033[32m████\033[1;33m█\033[1;32m████\033[1;36m█\033[32m█████▄\033[0m'
    tree_segment 8  '\033[32m▄████\033[1;35m█\033[32m███\033[1;36m█\033[1;32m█████\033[32m███\033[1;31m█\033[1;32m███\033[32m████▄\033[0m'
    tree_segment 6  '\033[32m▄████\033[1;33m██\033[32m███\033[1;31m█\033[1;32m████\033[1;37m█\033[32m████\033[1;35m█\033[32m███\033[1;33m██\033[32m████▄\033[0m'
    tree_segment 4  '\033[1;37m▀\033[32m█████\033[1;36m█\033[32m████\033[1;33m██\033[1;32m█████\033[1;31m█\033[32m████\033[1;33m██\033[32m███\033[1;35m█\033[32m█████\033[1;37m▀\033[0m'

    # Tier 5 (Wide Base Boughs - solid full blocks inside)
    tree_segment 9  '\033[32m▄████\033[1;31m█\033[1;32m████\033[32m███\033[1;36m█\033[1;32m████\033[1;33m█\033[32m█████▄\033[0m'
    tree_segment 7  '\033[32m▄█████\033[1;35m█\033[32m████\033[1;33m█\033[1;32m█████\033[32m████\033[1;31m█\033[1;32m███\033[32m███▄\033[0m'
    tree_segment 5  '\033[32m▄█████\033[1;36m█\033[1;32m████\033[32m███\033[1;35m█\033[1;32m████\033[1;37m█\033[32m████\033[1;33m█\033[1;32m███\033[32m████▄\033[0m'
    tree_segment 3  '\033[32m▄█████\033[1;33m██\033[32m████\033[1;31m█\033[1;32m█████\033[32m███\033[1;36m█\033[1;32m█████\033[1;35m█\033[32m███\033[1;33m██\033[32m███▄\033[0m'
    tree_segment 1  '\033[1;37m▀\033[32m██████\033[1;35m█\033[32m████\033[1;33m██\033[1;32m████\033[1;31m█\033[32m████\033[1;36m█\033[1;32m████\033[1;33m██\033[32m███\033[1;31m█\033[32m██████\033[1;37m▀\033[0m'

    # Trunk & 4 Gift Boxes (spaced 1 row below branches so bows never cut into the tree)
    tree_segment 19 '\033[33m█████\033[0m'

    tree_part 3  '\033[1;37m▄█▄█▄\033[0m'
    tree_part 11 '\033[1;33m▄█▄█▄\033[0m'
    tree_part 19 '\033[33m█████\033[0m'
    tree_part 27 '\033[1;37m▄█▄█▄\033[0m'
    tree_segment 35 '\033[1;33m▄█▄█▄\033[0m'

    tree_part 2  '\033[1;35m██\033[1;37m███\033[1;35m██\033[0m'
    tree_part 10 '\033[1;31m██\033[1;33m███\033[1;31m██\033[0m'
    tree_part 19 '\033[33m█████\033[0m'
    tree_part 26 '\033[1;36m██\033[1;37m███\033[1;36m██\033[0m'
    tree_segment 34 '\033[1;32m██\033[1;31m███\033[1;32m██\033[0m'

    tree_part 2  '\033[1;35m███\033[1;37m█\033[1;35m███\033[0m'
    tree_part 10 '\033[1;31m███\033[1;33m█\033[1;31m███\033[0m'
    tree_part 18 '\033[33m███████\033[0m'
    tree_part 26 '\033[1;36m███\033[1;37m█\033[1;36m███\033[0m'
    tree_segment 34 '\033[1;32m███\033[1;31m█\033[1;32m███\033[0m'
}

# ANSI Shadow ASCII Font (rows 0..6; row 0 is for accents)
get_ansi_shadow_line() {
    case "$BLK_CH" in
        A)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART=" █████╗ " ;;
                2) ROW_PART="██╔══██╗" ;;
                3) ROW_PART="███████║" ;;
                4) ROW_PART="██╔══██║" ;;
                5) ROW_PART="██║  ██║" ;;
                6) ROW_PART="╚═╝  ╚═╝" ;;
            esac ;;
        @)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="  ██╔╝  " ;;
                1) ROW_PART=" █████╗ " ;;
                2) ROW_PART="██╔══██╗" ;;
                3) ROW_PART="███████║" ;;
                4) ROW_PART="██╔══██║" ;;
                5) ROW_PART="██║  ██║" ;;
                6) ROW_PART="╚═╝  ╚═╝" ;;
            esac ;;
        B)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART="██████╗ " ;;
                2) ROW_PART="██╔══██╗" ;;
                3) ROW_PART="██████╔╝" ;;
                4) ROW_PART="██╔══██╗" ;;
                5) ROW_PART="██████╔╝" ;;
                6) ROW_PART="╚═════╝ " ;;
            esac ;;
        C)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART=" ██████╗" ;;
                2) ROW_PART="██╔════╝" ;;
                3) ROW_PART="██║     " ;;
                4) ROW_PART="██║     " ;;
                5) ROW_PART="╚██████╗" ;;
                6) ROW_PART=" ╚═════╝" ;;
            esac ;;
        D)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART="██████╗ " ;;
                2) ROW_PART="██╔══██╗" ;;
                3) ROW_PART="██║  ██║" ;;
                4) ROW_PART="██║  ██║" ;;
                5) ROW_PART="██████╔╝" ;;
                6) ROW_PART="╚═════╝ " ;;
            esac ;;
        G)
            CHAR_W=9
            case "$BLK_LN" in
                0) ROW_PART="         " ;;
                1) ROW_PART=" ██████╗ " ;;
                2) ROW_PART="██╔════╝ " ;;
                3) ROW_PART="██║  ███╗" ;;
                4) ROW_PART="██║   ██║" ;;
                5) ROW_PART="╚██████╔╝" ;;
                6) ROW_PART=" ╚═════╝ " ;;
            esac ;;
        H)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART="██╗  ██╗" ;;
                2) ROW_PART="██║  ██║" ;;
                3) ROW_PART="███████║" ;;
                4) ROW_PART="██╔══██║" ;;
                5) ROW_PART="██║  ██║" ;;
                6) ROW_PART="╚═╝  ╚═╝" ;;
            esac ;;
        I)
            CHAR_W=4
            case "$BLK_LN" in
                0) ROW_PART="    " ;;
                1) ROW_PART="██╗ " ;;
                2) ROW_PART="██║ " ;;
                3) ROW_PART="██║ " ;;
                4) ROW_PART="██║ " ;;
                5) ROW_PART="██║ " ;;
                6) ROW_PART="╚═╝ " ;;
            esac ;;
        K)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART="██╗  ██╗" ;;
                2) ROW_PART="██║ ██╔╝" ;;
                3) ROW_PART="█████╔╝ " ;;
                4) ROW_PART="██╔═██╗ " ;;
                5) ROW_PART="██║  ██╗" ;;
                6) ROW_PART="╚═╝  ╚═╝" ;;
            esac ;;
        L)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART="██╗     " ;;
                2) ROW_PART="██║     " ;;
                3) ROW_PART="██║     " ;;
                4) ROW_PART="██║     " ;;
                5) ROW_PART="███████╗" ;;
                6) ROW_PART="╚══════╝" ;;
            esac ;;
        M)
            CHAR_W=11
            case "$BLK_LN" in
                0) ROW_PART="           " ;;
                1) ROW_PART="███╗   ███╗" ;;
                2) ROW_PART="████╗ ████║" ;;
                3) ROW_PART="██╔████╔██║" ;;
                4) ROW_PART="██║╚██╔╝██║" ;;
                5) ROW_PART="██║ ╚═╝ ██║" ;;
                6) ROW_PART="╚═╝     ╚═╝" ;;
            esac ;;
        N)
            CHAR_W=10
            case "$BLK_LN" in
                0) ROW_PART="          " ;;
                1) ROW_PART="███╗   ██╗" ;;
                2) ROW_PART="████╗  ██║" ;;
                3) ROW_PART="██╔██╗ ██║" ;;
                4) ROW_PART="██║╚██╗██║" ;;
                5) ROW_PART="██║ ╚████║" ;;
                6) ROW_PART="╚═╝  ╚═══╝" ;;
            esac ;;
        O)
            CHAR_W=9
            case "$BLK_LN" in
                0) ROW_PART="         " ;;
                1) ROW_PART=" ██████╗ " ;;
                2) ROW_PART="██╔═══██╗" ;;
                3) ROW_PART="██║   ██║" ;;
                4) ROW_PART="██║   ██║" ;;
                5) ROW_PART="╚██████╔╝" ;;
                6) ROW_PART=" ╚═════╝ " ;;
            esac ;;
        P)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART="██████╗ " ;;
                2) ROW_PART="██╔══██╗" ;;
                3) ROW_PART="██████╔╝" ;;
                4) ROW_PART="██╔═══╝ " ;;
                5) ROW_PART="██║     " ;;
                6) ROW_PART="╚═╝     " ;;
            esac ;;
        R)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART="██████╗ " ;;
                2) ROW_PART="██╔══██╗" ;;
                3) ROW_PART="██████╔╝" ;;
                4) ROW_PART="██╔══██╗" ;;
                5) ROW_PART="██║  ██║" ;;
                6) ROW_PART="╚═╝  ╚═╝" ;;
            esac ;;
        S)
            CHAR_W=8
            case "$BLK_LN" in
                0) ROW_PART="        " ;;
                1) ROW_PART="███████╗" ;;
                2) ROW_PART="██╔════╝" ;;
                3) ROW_PART="███████╗" ;;
                4) ROW_PART="╚════██║" ;;
                5) ROW_PART="███████║" ;;
                6) ROW_PART="╚══════╝" ;;
            esac ;;
        T)
            CHAR_W=9
            case "$BLK_LN" in
                0) ROW_PART="         " ;;
                1) ROW_PART="████████╗" ;;
                2) ROW_PART="╚══██╔══╝" ;;
                3) ROW_PART="   ██║   " ;;
                4) ROW_PART="   ██║   " ;;
                5) ROW_PART="   ██║   " ;;
                6) ROW_PART="   ╚═╝   " ;;
            esac ;;
        Y)
            CHAR_W=9
            case "$BLK_LN" in
                0) ROW_PART="         " ;;
                1) ROW_PART="██╗   ██╗" ;;
                2) ROW_PART="╚██╗ ██╔╝" ;;
                3) ROW_PART=" ╚████╔╝ " ;;
                4) ROW_PART="  ╚██╔╝  " ;;
                5) ROW_PART="   ██║   " ;;
                6) ROW_PART="   ╚═╝   " ;;
            esac ;;
        !)
            CHAR_W=3
            case "$BLK_LN" in
                0) ROW_PART="   " ;;
                1) ROW_PART="██╗" ;;
                2) ROW_PART="██║" ;;
                3) ROW_PART="██║" ;;
                4) ROW_PART="╚═╝" ;;
                5) ROW_PART="██╗" ;;
                6) ROW_PART="╚═╝" ;;
            esac ;;
        0)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART=" ████╗ " ;;
                2) ROW_PART="██╔═██╗" ;;
                3) ROW_PART="██║ ██║" ;;
                4) ROW_PART="██║ ██║" ;;
                5) ROW_PART="╚████╔╝" ;;
                6) ROW_PART=" ╚═══╝ " ;;
            esac ;;
        1)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART="  ██╗  " ;;
                2) ROW_PART=" ███║  " ;;
                3) ROW_PART=" ╚██║  " ;;
                4) ROW_PART="  ██║  " ;;
                5) ROW_PART="  ██║  " ;;
                6) ROW_PART="  ╚═╝  " ;;
            esac ;;
        2)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART="█████╗ " ;;
                2) ROW_PART="╚═══██╗" ;;
                3) ROW_PART=" ████╔╝" ;;
                4) ROW_PART="██╔══╝ " ;;
                5) ROW_PART="██████╗" ;;
                6) ROW_PART="╚═════╝" ;;
            esac ;;
        3)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART="█████╗ " ;;
                2) ROW_PART="╚═══██╗" ;;
                3) ROW_PART=" ████╔╝" ;;
                4) ROW_PART=" ╚══██╗" ;;
                5) ROW_PART="█████╔╝" ;;
                6) ROW_PART="╚════╝ " ;;
            esac ;;
        4)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART="██╗ ██╗" ;;
                2) ROW_PART="██║ ██║" ;;
                3) ROW_PART="██████║" ;;
                4) ROW_PART="╚═══██║" ;;
                5) ROW_PART="    ██║" ;;
                6) ROW_PART="    ╚═╝" ;;
            esac ;;
        5)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART="██████╗" ;;
                2) ROW_PART="██╔═══╝" ;;
                3) ROW_PART="█████╗ " ;;
                4) ROW_PART="╚═══██╗" ;;
                5) ROW_PART="█████╔╝" ;;
                6) ROW_PART="╚════╝ " ;;
            esac ;;
        6)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART=" ████╗ " ;;
                2) ROW_PART="██╔══╝ " ;;
                3) ROW_PART="█████╗ " ;;
                4) ROW_PART="██╔═██╗" ;;
                5) ROW_PART="╚████╔╝" ;;
                6) ROW_PART=" ╚═══╝ " ;;
            esac ;;
        7)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART="██████╗" ;;
                2) ROW_PART="╚═══██║" ;;
                3) ROW_PART="   ██╔╝" ;;
                4) ROW_PART="  ██╔╝ " ;;
                5) ROW_PART="  ██║  " ;;
                6) ROW_PART="  ╚═╝  " ;;
            esac ;;
        8)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART=" ████╗ " ;;
                2) ROW_PART="██╔═██╗" ;;
                3) ROW_PART="╚████╔╝" ;;
                4) ROW_PART="██╔═██╗" ;;
                5) ROW_PART="╚████╔╝" ;;
                6) ROW_PART=" ╚═══╝ " ;;
            esac ;;
        9)
            CHAR_W=7
            case "$BLK_LN" in
                0) ROW_PART="       " ;;
                1) ROW_PART=" ████╗ " ;;
                2) ROW_PART="██╔═██╗" ;;
                3) ROW_PART="╚█████║" ;;
                4) ROW_PART=" ╚══██║" ;;
                5) ROW_PART=" ████╔╝" ;;
                6) ROW_PART=" ╚═══╝ " ;;
            esac ;;
        :)
            CHAR_W=4
            case "$BLK_LN" in
                0) ROW_PART="    " ;;
                1) ROW_PART="    " ;;
                2) ROW_PART=" ██╗" ;;
                3) ROW_PART=" ╚═╝" ;;
                4) ROW_PART=" ██╗" ;;
                5) ROW_PART=" ╚═╝" ;;
                6) ROW_PART="    " ;;
            esac ;;
        *)
            CHAR_W=4
            ROW_PART="    " ;;
    esac
}

draw_ansi_word_centered() {
    local word="$1"
    local first_line="$2"
    local color_seq="$3"

    local word_len=${#word}
    local word_w=0
    local i=0
    BLK_LN=1
    while (( i < word_len )); do
        BLK_CH="${word:i:1}"
        get_ansi_shadow_line
        word_w=$(( word_w + CHAR_W ))
        i=$(( i + 1 ))
    done

    local start_c=$(( RIGHT_COL + (RIGHT_W - word_w) / 2 ))
    if (( start_c < RIGHT_COL )); then
        start_c="$RIGHT_COL"
    fi

    local l="$first_line"
    while (( l <= 6 )); do
        BLK_LN="$l"
        local out=""
        i=0
        while (( i < word_len )); do
            BLK_CH="${word:i:1}"
            get_ansi_shadow_line
            out+="$ROW_PART"
            i=$(( i + 1 ))
        done
        CUR_C="$start_c"
        buf_move
        FRAME_BUF+="$color_seq"
        FRAME_BUF+="$out"
        FRAME_BUF+="\033[0m"
        CUR_R=$(( CUR_R + 1 ))
        l=$(( l + 1 ))
    done
}

center_in_right() {
    local color_seq="$1"
    local text="$2"
    local len=${#text}
    CUR_C=$(( RIGHT_COL + (RIGHT_W - len) / 2 ))
    if (( CUR_C < RIGHT_COL )); then
        CUR_C="$RIGHT_COL"
    fi
    buf_move
    FRAME_BUF+="$color_seq"
    FRAME_BUF+="$text"
    FRAME_BUF+="\033[0m"
}

draw_greeting_panel() {
    local start_r=$(( (TERM_ROWS - 14) / 2 + 1 ))
    if (( start_r < 3 )); then
        start_r=3
    fi

    if [ "$GREETING_LANG" = "HU" ]; then
        CUR_R="$start_r"
        draw_ansi_word_centered "BOLDOG" 1 '\033[1;31m'
        CUR_R=$(( start_r + 7 ))
        draw_ansi_word_centered "KAR@CSONYT!" 0 '\033[1;32m'
    else
        CUR_R="$start_r"
        draw_ansi_word_centered "HAPPY" 1 '\033[1;31m'
        CUR_R=$(( start_r + 8 ))
        draw_ansi_word_centered "CHRISTMAS!" 1 '\033[1;32m'
    fi
}

draw_countdown_panel() {
    local remaining="$1"

    local days=$(( remaining / 86400 ))
    local rem=$(( remaining % 86400 ))
    local hours=$(( rem / 3600 ))
    rem=$(( rem % 3600 ))
    local mins=$(( rem / 60 ))
    local secs=$(( rem % 60 ))

    local d_str h_str m_str s_str clock_str
    printf -v d_str '%02d:' "$days"
    printf -v h_str '%02d:' "$hours"
    printf -v m_str '%02d:' "$mins"
    printf -v s_str '%02d' "$secs"
    clock_str=""
    clock_str+="$d_str"
    clock_str+="$h_str"
    clock_str+="$m_str"
    clock_str+="$s_str"

    local center_r=$(( TERM_ROWS / 2 - 3 ))
    if (( center_r < 4 )); then
        center_r=4
    fi

    CUR_R=$(( center_r - 2 ))
    center_in_right '\033[1;36m' "DAYS (NAP)       HOURS (ORA)      MINS (PERC)      SECS (MP)"
    CUR_R="$center_r"
    draw_ansi_word_centered "$clock_str" 1 '\033[1;33m'
}

sanitize_num() {
    local val="$1"
    val="${val//[^0-9]/}"
    val="${val##+(0)}"
    if [ -z "$val" ]; then
        CLEAN_NUM=0
    else
        CLEAN_NUM="$val"
    fi
}

set_auto_countdown_target() {
    TARGET_TS=$(LC_ALL=C date -d 'Dec 24 18:00:00' +%s 2>/dev/null || echo 0)
    if (( TARGET_TS == 0 )); then
        TARGET_TS=$(date -j 1224180000 +%s 2>/dev/null || echo 0)
    fi
}

prompt_menu() {
    update_layout
    clear
    FRAME_BUF="\033[?2026h"
    draw_snow
    draw_tree
    FRAME_BUF+="\033[?2026l"
    printf '%b' "$FRAME_BUF"

    local prompt_c=$(( RIGHT_COL + 2 ))
    local mid_r=$(( TERM_ROWS / 2 - 4 ))
    if (( mid_r < 4 )); then
        mid_r=4
    fi

    tput cnorm 2>/dev/null || printf '\033[?25h'
    CUR_R="$mid_r"
    CUR_C="$prompt_c"
    move_cursor
    printf '\033[1;33mMode? [1=Countdown / a=Auto-Countdown (Dec 24 18:00) / 2=Greeting / q=Quit]: \033[0m'
    local mode_choice=""
    read -r mode_choice
    mode_choice="${mode_choice,,}"

    case "$mode_choice" in
        q|quit|exit)
            cleanup
            ;;
        a|auto|auto-countdown|autocountdown|3)
            SELECTED_MODE="COUNTDOWN"
            set_auto_countdown_target
            ;;
        1|c|countdown|count*)
            SELECTED_MODE="COUNTDOWN"
            local in_days=""
            local in_hours=""
            local in_mins=""
            local in_secs=""

            CUR_R=$(( mid_r + 2 ))
            CUR_C="$prompt_c"
            move_cursor
            printf '\033[37mNap (Days, vagy "a"=Auto Dec 24 18:00) [0]: \033[0m'
            read -r in_days

            if [[ "${in_days,,}" == a* ]]; then
                set_auto_countdown_target
            else
                CUR_R=$(( mid_r + 3 ))
                CUR_C="$prompt_c"
                move_cursor
                printf '\033[37mOra (Hours)                            [0]: \033[0m'
                read -r in_hours

                CUR_R=$(( mid_r + 4 ))
                CUR_C="$prompt_c"
                move_cursor
                printf '\033[37mPerc (Minutes)                         [1]: \033[0m'
                read -r in_mins

                CUR_R=$(( mid_r + 5 ))
                CUR_C="$prompt_c"
                move_cursor
                printf '\033[37mMasodperc (Secs)                       [0]: \033[0m'
                read -r in_secs

                if [ -z "$in_days" ]; then
                    if [ -z "$in_hours" ]; then
                        if [ -z "$in_mins" ]; then
                            if [ -z "$in_secs" ]; then
                                in_mins=1
                            fi
                        fi
                    fi
                fi

                sanitize_num "$in_days"
                local d_num="$CLEAN_NUM"
                sanitize_num "$in_hours"
                local h_num="$CLEAN_NUM"
                sanitize_num "$in_mins"
                local m_num="$CLEAN_NUM"
                sanitize_num "$in_secs"
                local s_num="$CLEAN_NUM"

                COUNTDOWN_TOTAL=$(( d_num * 86400 + h_num * 3600 + m_num * 60 + s_num ))
                local now_ts
                now_ts=$(date +%s)
                TARGET_TS=$(( now_ts + COUNTDOWN_TOTAL ))
            fi
            ;;
        2|g|greeting|greet*)
            SELECTED_MODE="GREETING"
            CUR_R=$(( mid_r + 2 ))
            CUR_C="$prompt_c"
            move_cursor
            printf '\033[1;36mMagyar vagy English? [M/E]: \033[0m'
            local lang_choice=""
            read -r lang_choice
            lang_choice="${lang_choice,,}"
            case "$lang_choice" in
                e|en|eng|english|2)
                    GREETING_LANG="EN"
                    ;;
                *)
                    GREETING_LANG="HU"
                    ;;
            esac
            ;;
        *)
            SELECTED_MODE="INVALID"
            ;;
    esac
    tput civis 2>/dev/null || printf '\033[?25l'
}

run_greeting_loop() {
    local key=""
    while true; do
        update_layout
        FRAME_BUF="\033[?2026h"
        draw_snow
        draw_tree
        draw_greeting_panel
        FRAME_BUF+="\033[?2026l"
        printf '%b' "$FRAME_BUF"

        TICK=$(( TICK + 1 ))
        if read -r -s -n 1 -t 0.25 key 2>/dev/null; then
            key="${key,,}"
            case "$key" in
                q) cleanup ;;
                m) return 0 ;;
            esac
        fi
    done
}

run_countdown_loop() {
    local key=""

    while true; do
        update_layout
        local now_ts
        now_ts=$(date +%s)
        local rem=$(( TARGET_TS - now_ts ))
        if (( rem <= 0 )); then
            GREETING_LANG="HU"
            run_greeting_loop
            return 0
        fi

        FRAME_BUF="\033[?2026h"
        draw_snow
        draw_tree
        draw_countdown_panel "$rem"
        FRAME_BUF+="\033[?2026l"
        printf '%b' "$FRAME_BUF"

        TICK=$(( TICK + 1 ))
        if read -r -s -n 1 -t 0.25 key 2>/dev/null; then
            key="${key,,}"
            case "$key" in
                q) cleanup ;;
                m) return 0 ;;
            esac
        fi
    done
}

tput smcup 2>/dev/null || true
tput civis 2>/dev/null || printf '\033[?25l'

while true; do
    SELECTED_MODE=""
    prompt_menu
    if [ "$SELECTED_MODE" = "COUNTDOWN" ]; then
        run_countdown_loop
    elif [ "$SELECTED_MODE" = "GREETING" ]; then
        run_greeting_loop
    fi
done