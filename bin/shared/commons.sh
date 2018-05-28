#!/usr/bin/env bash

function contains {
    string="$1"
    search_string="$2"

    if echo ${string} | grep -iqF ${search_string}; then
        echo true
    else
        echo false
    fi
}

function get_group {
    group=`awk '/group/{print $NF}' build.gradle | sed s/\'//g`
    echo ${group}
}

function get_name {
    name=`awk '/rootProject.name/{print $NF}' settings.gradle | sed s/\'//g`
    echo ${name}
}

function get_version {
    version=`sed s/version=//g gradle.properties`
    echo ${version}
}

function mask_string {
    string="$1"
    value=`echo ${string} | sed 's/./\*/g'`
    echo ${value}
}

function read_password_input {
    unset password;
    password=""
    while IFS= read -r -s -n1 input; do
      [[ -z ${input} ]] && { printf '\n' >&2; break; }
      if [[ ${input} == $'\x7f' ]]; then
          [[ -n ${password} ]] && password=${password%?}
          printf '\b \b' >&2
      else
        password+=${input}
        printf '*' >&2
      fi
    done
    echo ${password}
}

function remove_special_chars {
    string="$1"
    value=`echo ${string} | sed 's/[-_+. ]//g'`
    echo ${value}
}

function remove_special_chars_but_period {
    string="$1"
    value=`echo ${string} | sed 's/[-_+ ]//g'`
    echo ${value}
}

function remove_whitespace_chars {
    string="$1"
    value=`echo ${string} | sed 's/[ ]//g'`
    echo ${value}
}

function replace_special_chars_with_dash {
    string="$1"
    value=`echo ${string} | sed 's/[_+. ]/-/g'`
    echo ${value}
}

function replace_special_chars_with_whitespace {
    string="$1"
    value=`echo ${string} | sed 's/[-_+.]/ /g'`
    echo ${value}
}

function to_lower_case {
    string="$1"
    value=`echo ${string} | awk '{print tolower($0)}'`
    echo ${value}
}

function to_title_case {
    string="$1"
    value=`echo ${string} | perl -ane 'foreach $wrd ( @F ) { print ucfirst($wrd)." "; } print "\n" ; '`
    echo ${value}
}

function to_upper_case {
    string="$1"
    value=`echo ${string} | awk '{print toupper($0)}'`
    echo ${value}
}
