#!/usr/bin/env bash
# Written in [Amber](https://amber-lang.com/)
# version: 0.6.0-alpha
# error(message: Text, code: Int)
error__0_v0() {
    local message_10="${1}"
    local code_11="${2}"
    printf '%s
' "${message_10}" >&2
    __status=$?
    exit "${code_11}"
}

# env_or(name: Text, fallback: Text)
env_or__1_v0() {
    local name_4="${1}"
    local fallback_5="${2}"
    local command_0
    command_0="$(/usr/bin/printenv "${name_4}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_env_or1_v0="${fallback_5}"
        return 0
    fi
    local value_6="${command_0}"
    if [ "$([ "_${value_6}" != "_" ]; echo $?)" != 0 ]; then
        ret_env_or1_v0="${fallback_5}"
        return 0
    fi
    ret_env_or1_v0="${value_6}"
    return 0
}

# real_path(path: Text)
real_path__2_v0() {
    local path_19="${1}"
    local command_1
    command_1="$(resolved=$(/bin/realpath -- "${path_19}" && printf '.') || exit 1
        newline=$'\n'
        resolved="${resolved%"$newline."}"
        if [[ "$resolved" == *"$newline" ]]; then exit 1; fi
        printf '%s' "$resolved")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_real_path2_v0=''
        return "${__status}"
    fi
    local output_20="${command_1}"
    ret_real_path2_v0="${output_20}"
    return 0
}

# file_exists(path: Text)
file_exists__3_v0() {
    local path_53="${1}"
    test -e "${path_53}" || test -L "${path_53}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_file_exists3_v0=0
        return 0
    fi
    ret_file_exists3_v0=1
    return 0
}

# ensure_directory(path: Text)
ensure_directory__4_v0() {
    local path_49="${1}"
    /bin/mkdir -p -- "${path_49}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not create directory: ${path_49}" 1
    fi
}

# lock_file(path: Text)
lock_file__5_v0() {
    local path_51="${1}"
    # lockf on an inherited descriptor keeps the lock until this shell exits.
    test ! -L "${path_51}" && exec 9>>"${path_51}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not open lock: ${path_51}" 1
    fi
    /usr/bin/lockf -t 15 9
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not acquire lock: ${path_51}" 1
    fi
}

# write_file(path: Text, data: Text)
write_file__6_v0() {
    local path_109="${1}"
    local data_110="${2}"
    local command_2
    command_2="$(/usr/bin/mktemp "${path_109}.XXXXXX")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not stage: ${path_109}" 1
    fi
    local temp_111="${command_2}"
    printf '%s
' "${data_110}" > "${temp_111}" && /bin/mv -f -h -- "${temp_111}" "${path_109}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        /bin/rm -f -- "${temp_111}"
        __status=$?
        error__0_v0 "Could not save: ${path_109}" 1
    fi
}

# strip_json_lines(input: Text)
strip_json_lines__7_v0() {
    local input_78="${1}"
    local command_3
    command_3="$(printf '%s' "${input_78}" | /usr/bin/jq -cs '.')"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_strip_json_lines7_v0=''
        return "${__status}"
    fi
    local result_79="${command_3}"
    ret_strip_json_lines7_v0="${result_79}"
    return 0
}

# valid_slug(slug: Text)
valid_slug__17_v0() {
    local slug_48="${1}"
    LC_ALL=C; [[ "${slug_48}" =~ ^[a-z0-9][a-z0-9-]*$ ]]
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_valid_slug17_v0=0
        return 0
    fi
    ret_valid_slug17_v0=1
    return 0
}

# references_filter()
references_filter__18_v0() {
    ret_references_filter18_v0="def paths: type == \"array\" and all(.[]; type == \"string\" and startswith(\"/\") and (contains(\"\\u0000\") | not)) and (unique | length) == length;
        if length == 1 and (.[0] | type == \"object\" and (.directories | paths) and ((.files // []) | paths))
        then .[0] else error(\"Invalid references.json\") end"
    return 0
}

# read_references(path: Text)
read_references__19_v0() {
    local path_55="${1}"
    local file_56="${path_55}/references.json"
    references_filter__18_v0 
    local filter_57="${ret_references_filter18_v0}"
    test -d "${path_55}" && test ! -L "${path_55}" && test -f "${file_56}" && test ! -L "${file_56}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_read_references19_v0=''
        return "${__status}"
    fi
    local command_4
    command_4="$(/usr/bin/jq -ces "${filter_57}" -- "${file_56}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_read_references19_v0=''
        return "${__status}"
    fi
    local refs_58="${command_4}"
    ret_read_references19_v0="${refs_58}"
    return 0
}

# create_workspace(root: Text, slug: Text)
create_workspace__20_v0() {
    local root_46="${1}"
    local slug_47="${2}"
    valid_slug__17_v0 "${slug_47}"
    local ret_valid_slug17_v0__23_12="${ret_valid_slug17_v0}"
    if [ "$(( ! ret_valid_slug17_v0__23_12 ))" != 0 ]; then
        error__0_v0 "Invalid workspace slug: ${slug_47}" 2
    fi
    ensure_directory__4_v0 "${root_46}"
    real_path__2_v0 "${root_46}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid workspace root: ${root_46}" 1
    fi
    local physical_50="${ret_real_path2_v0}"
    lock_file__5_v0 "${physical_50}/.create.lock"
    local path_52="${physical_50}/${slug_47}"
    file_exists__3_v0 "${path_52}"
    local ret_file_exists3_v0__28_12="${ret_file_exists3_v0}"
    if [ "$(( ! ret_file_exists3_v0__28_12 ))" != 0 ]; then
        local command_5
        command_5="$(/usr/bin/mktemp -d "${physical_50}/.workspace.XXXXXX")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not stage workspace: ${slug_47}" 1
        fi
        local stage_54="${command_5}"
        printf '%s
' '{"directories":[]}' > "${stage_54}/references.json" && /bin/mv -n -h -- "${stage_54}" "${path_52}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not create workspace: ${slug_47}" 1
        fi
    fi
    read_references__19_v0 "${path_52}">/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid workspace: ${path_52}" 1
    fi
    local refs_59="${ret_read_references19_v0}"
    test -n "${refs_59}"
    __status=$?
    printf '%s\n' "${path_52}"
}

# list_workspaces(root: Text, current: Text, as_json: Bool)
list_workspaces__21_v0() {
    local root_73="${1}"
    local current_74="${2}"
    local as_json_75="${3}"
    references_filter__18_v0 
    local refs_filter_76="${ret_references_filter18_v0}"
    local command_6
    command_6="$(LC_ALL=C; export LC_ALL; issue=0
        for path in "${root_73}"/*; do
            test -d "$path" && test ! -L "$path" || continue
            slug=${path##*/}
            [[ "$slug" =~ ^[a-z0-9][a-z0-9-]*$ ]] || continue
            file="$path/references.json"
            test -e "$file" || test -L "$file" || continue
            if test ! -f "$file" || test -L "$file"; then
                printf 'Invalid references: %s
' "$file" >&2
                issue=1
                continue
            fi
            if ! refs=$(/usr/bin/jq -ces "${refs_filter_76}" -- "$file"); then
                printf 'Invalid references: %s
' "$file" >&2
                issue=1
                continue
            fi
            /usr/bin/jq -c --arg slug "$slug" --arg path "$path" --arg cwd "${current_74}" '
                def under($base): $cwd == $base or ($cwd | startswith(if $base == "/" then "/" else $base + "/" end));
                select($cwd == "" or under($path) or any(.directories[]; under(.)))
                | { $slug, $path }
            ' <<< "$refs" || issue=1
        done
        printf '%s
' "$issue")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not list workspaces" 1
    fi
    local result_77="${command_6}"
    strip_json_lines__7_v0 "${result_77}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read workspace list" 1
    fi
    local rows_80="${ret_strip_json_lines7_v0}"
    local command_7
    command_7="$(/usr/bin/jq -r 'last' <<< "${rows_80}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read workspace status" 1
    fi
    local code_81="${command_7}"
    if [ "${as_json_75}" != 0 ]; then
        /usr/bin/jq -c '{workspaces: .[:-1]}' <<< "${rows_80}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not print workspace list" 1
        fi
    else
        /usr/bin/jq -r '.[:-1][] | [.slug, .path] | @tsv' <<< "${rows_80}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not print workspace list" 1
        fi
    fi
    if [ "$([ "_${code_81}" != "_1" ]; echo $?)" != 0 ]; then
        exit 1
    fi
}

# update_reference(root: Text, key: Text, action: Text, slug: Text, input: Text)
update_reference__22_v0() {
    local root_99="${1}"
    local key_100="${2}"
    local action_101="${3}"
    local slug_102="${4}"
    local input_103="${5}"
    valid_slug__17_v0 "${slug_102}"
    local ret_valid_slug17_v0__77_12="${ret_valid_slug17_v0}"
    if [ "$(( ! ret_valid_slug17_v0__77_12 ))" != 0 ]; then
        error__0_v0 "Invalid workspace slug: ${slug_102}" 2
    fi
    local target_104="${input_103}"
    if [ "$([ "_${action_101}" != "_add" ]; echo $?)" != 0 ]; then
        real_path__2_v0 "${input_103}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Path not found: ${input_103}" 1
        fi
        target_104="${ret_real_path2_v0}"
        if [ "$([ "_${key_100}" != "_directories" ]; echo $?)" != 0 ]; then
            test -d "${target_104}"
            __status=$?
            if [ "${__status}" != 0 ]; then
                error__0_v0 "Not a directory: ${target_104}" 1
            fi
        else
            test -f "${target_104}"
            __status=$?
            if [ "${__status}" != 0 ]; then
                error__0_v0 "Not a regular file: ${target_104}" 1
            fi
        fi
    fi
    if [ "$([ "_${action_101}" != "_remove" ]; echo $?)" != 0 ]; then
        [[ "${target_104}" == /* ]]
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Use the registered absolute path" 2
        fi
    fi
    if [ "$(( $([ "_${action_101}" == "_add" ]; echo $?) && $([ "_${action_101}" == "_remove" ]; echo $?) ))" != 0 ]; then
        error__0_v0 "Expected add or remove" 2
    fi
    local path_105="${root_99}/${slug_102}"
    read_references__19_v0 "${path_105}">/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Workspace not found or invalid: ${slug_102}" 1
    fi
    local existing_106="${ret_read_references19_v0}"
    test -n "${existing_106}"
    __status=$?
    lock_file__5_v0 "${path_105}/.references.lock"
    read_references__19_v0 "${path_105}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid workspace: ${path_105}" 1
    fi
    local refs_107="${ret_read_references19_v0}"
    local command_8
    command_8="$(/usr/bin/jq -ce --arg key "${key_100}" --arg action "${action_101}" --arg item "${target_104}" '
        if $action == "add" then
          .[$key] = ((.[$key] // []) | if index($item) == null then . + [$item] else . end)
        elif ((.[$key] // []) | index($item)) != null then
          .[$key] |= map(select(. != $item))
        else error("Path not registered") end
    ' <<< "${refs_107}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not ${action_101} reference: ${target_104}" 1
    fi
    local changed_108="${command_8}"
    if [ "$([ "_${changed_108}" == "_${refs_107}" ]; echo $?)" != 0 ]; then
        write_file__6_v0 "${path_105}/references.json" "${changed_108}"
    fi
    printf '%s\n' "${target_104}"
}

# Git inside a submodule resolves the submodule first, so walk outwards to the enclosing worktree.
# enclosing_worktree(root: Text)
enclosing_worktree__23_v0() {
    local root_184="${1}"
    local command_9
    command_9="$(pwd -P)"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_enclosing_worktree23_v0=""
        return 0
    fi
    local current_185="${command_9}"
    while [ "$([ "_${current_185}" == "_/" ]; echo $?)" != 0 ]; do
        [[ "${current_185}" == "${root_184}/"*/worktrees/* ]]
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_enclosing_worktree23_v0=""
            return 0
        fi
        local command_10
        command_10="$(/usr/bin/git -C "${current_185}" rev-parse --show-toplevel 2>/dev/null)"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_enclosing_worktree23_v0=""
            return 0
        fi
        local git_tree_186="${command_10}"
        if [ "$([ "_${git_tree_186}" != "_${current_185}" ]; echo $?)" != 0 ]; then
            local command_11
            command_11="$(/usr/bin/git -C "${current_185}" rev-parse --absolute-git-dir 2>/dev/null)"
            __status=$?
            if [ "${__status}" != 0 ]; then
                ret_enclosing_worktree23_v0=""
                return 0
            fi
            local git_dir_187="${command_11}"
            local command_12
            command_12="$(/usr/bin/git -C "${current_185}" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
            __status=$?
            if [ "${__status}" != 0 ]; then
                ret_enclosing_worktree23_v0=""
                return 0
            fi
            local common_dir_188="${command_12}"
            if [ "$([ "_${git_dir_187}" == "_${common_dir_188}" ]; echo $?)" != 0 ]; then
                ret_enclosing_worktree23_v0="${current_185}"
                return 0
            fi
        fi
        local command_13
        command_13="$(/usr/bin/dirname -- "${current_185}")"
        __status=$?
        if [ "${__status}" != 0 ]; then
            ret_enclosing_worktree23_v0=""
            return 0
        fi
        current_185="${command_13}"
    done
    ret_enclosing_worktree23_v0=""
    return 0
}

# current_owner(root: Text)
current_owner__24_v0() {
    local root_183="${1}"
    enclosing_worktree__23_v0 "${root_183}"
    local tree_189="${ret_enclosing_worktree23_v0}"
    if [ "$([ "_${tree_189}" != "_" ]; echo $?)" != 0 ]; then
        ret_current_owner24_v0=""
        return 0
    fi
    local command_14
    command_14="$(tree="${tree_189}"; rel="${tree#"${root_183}/"}"; printf '%s' "${rel%%/*}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_current_owner24_v0=""
        return 0
    fi
    local slug_190="${command_14}"
    ret_current_owner24_v0="${slug_190}"
    return 0
}

# selected_workspace(root: Text, slug: Text)
selected_workspace__25_v0() {
    local root_180="${1}"
    local slug_181="${2}"
    local selected_182="${slug_181}"
    if [ "$([ "_${selected_182}" != "_" ]; echo $?)" != 0 ]; then
        current_owner__24_v0 "${root_180}"
        selected_182="${ret_current_owner24_v0}"
    fi
    if [ "$([ "_${selected_182}" != "_" ]; echo $?)" != 0 ]; then
        error__0_v0 "Specify --workspace <project-slug>" 2
    fi
    valid_slug__17_v0 "${selected_182}"
    local ret_valid_slug17_v0__137_12="${ret_valid_slug17_v0}"
    if [ "$(( ! ret_valid_slug17_v0__137_12 ))" != 0 ]; then
        error__0_v0 "Invalid workspace slug: ${selected_182}" 2
    fi
    local path_191="${root_180}/${selected_182}"
    read_references__19_v0 "${path_191}">/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Workspace not found or invalid: ${selected_182}" 1
    fi
    local refs_192="${ret_read_references19_v0}"
    test -n "${refs_192}"
    __status=$?
    ret_selected_workspace25_v0="${selected_182}"
    return 0
}

# workspace_run(root: Text, args: [Text])
workspace_run__29_v0() {
    local root_173="${1}"
    local args_174=("${!2}")
    local __length_15=("${args_174[@]}")
    if [ "$(( ${#__length_15[@]} < 3 ))" != 0 ]; then
        error__0_v0 "Usage: workspace run <name> [--workspace <slug>] [-- <args>...]" 2
    fi
    local name_175="${args_174[2]?"Index out of bounds (at src/run.ab:6:23)"}"
    local slug_176=""
    local forwarded_177=()
    local index_178=3
    local __length_17=("${args_174[@]}")
    while [ "$(( index_178 < ${#__length_17[@]} ))" != 0 ]; do
        local flag_179="${args_174[${index_178}]?"Index out of bounds (at src/run.ab:11:27)"}"
        index_178="$(( index_178 + 1 ))"
        if [ "$([ "_${flag_179}" != "_--workspace" ]; echo $?)" != 0 ]; then
            local __length_18=("${args_174[@]}")
            if [ "$(( $(( index_178 >= ${#__length_18[@]} )) || $([ "_${slug_176}" == "_" ]; echo $?) ))" != 0 ]; then
                error__0_v0 "Specify one workspace" 2
            fi
            slug_176="${args_174[${index_178}]?"Index out of bounds (at src/run.ab:15:25)"}"
            valid_slug__17_v0 "${slug_176}"
            local ret_valid_slug17_v0__16_20="${ret_valid_slug17_v0}"
            if [ "$(( ! ret_valid_slug17_v0__16_20 ))" != 0 ]; then
                error__0_v0 "Invalid workspace slug: ${slug_176}" 2
            fi
            index_178="$(( index_178 + 1 ))"
            continue
        fi
        if [ "$(( $([ "_${flag_179}" != "_--" ]; echo $?) && $([ "_${name_175}" == "_--list" ]; echo $?) ))" != 0 ]; then
            local __length_19=("${args_174[@]}")
            while [ "$(( index_178 < ${#__length_19[@]} ))" != 0 ]; do
                forwarded_177+=("${args_174[${index_178}]?"Index out of bounds (at src/run.ab:22:36)"}")
                index_178="$(( index_178 + 1 ))"
            done
            break
        fi
        error__0_v0 "Unknown run option: ${flag_179}" 2
    done
    selected_workspace__25_v0 "${root_173}" "${slug_176}"
    local selected_193="${ret_selected_workspace25_v0}"
    local workplace_194="${root_173}/${selected_193}"
    local file_195="${workplace_194}/scripts.json"
    file_exists__3_v0 "${file_195}"
    local ret_file_exists3_v0__33_12="${ret_file_exists3_v0}"
    if [ "$(( ! ret_file_exists3_v0__33_12 ))" != 0 ]; then
        if [ "$([ "_${name_175}" != "_--list" ]; echo $?)" != 0 ]; then
            exit 0
        fi
        error__0_v0 "Script not found: ${name_175}" 1
    fi
    test -f "${file_195}" && test ! -L "${file_195}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid scripts file: ${file_195}" 1
    fi
    local command_21
    command_21="$(/usr/bin/jq -ces '
      select(length == 1) | .[0] | select(type == "object" and all(to_entries[];
        (.key | length > 0) and (.value | type == "object"
        and (.command | type == "string" and length > 0 and (contains("\u0000") | not))
        and ((.cwd // "/") | type == "string" and length > 0 and (contains("\u0000") | not)))))
    ' -- "${file_195}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Invalid scripts file: ${file_195}" 1
    fi
    local definitions_196="${command_21}"
    if [ "$([ "_${name_175}" != "_--list" ]; echo $?)" != 0 ]; then
        /usr/bin/jq -r 'keys[]' <<< "${definitions_196}"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not list scripts" 1
        fi
        exit 0
    fi
    local command_22
    command_22="$(/usr/bin/jq -ce --arg name "${name_175}" '.[$name]' <<< "${definitions_196}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Script not found: ${name_175}" 1
    fi
    local entry_197="${command_22}"
    local command_23
    command_23="$(/usr/bin/jq -r '.command' <<< "${entry_197}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read script: ${name_175}" 1
    fi
    local script_198="${command_23}"
    local command_24
    command_24="$(/usr/bin/jq -r '.cwd // "."' <<< "${entry_197}")"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not read cwd: ${name_175}" 1
    fi
    local relative_199="${command_24}"
    enclosing_worktree__23_v0 "${root_173}"
    local tree_200="${ret_enclosing_worktree23_v0}"
    local base_201="${workplace_194}"
    [[ "${tree_200}" == "${workplace_194}/worktrees/"* ]]
    __status=$?
    if [ "${__status}" = 0 ]; then
        base_201="${tree_200}"
    fi
    local cwd_202="${base_201}/${relative_199}"
    [[ "${relative_199}" == /* ]]
    __status=$?
    if [ "${__status}" = 0 ]; then
        cwd_202="${relative_199}"
    fi
    cd -- "${cwd_202}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not open script directory: ${cwd_202}" 1
    fi
    exec /bin/sh -c "${script_198}" "${name_175}" "${forwarded_177[@]}"
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "Could not execute script: ${name_175}" 1
    fi
}

# usage()
usage__37_v0() {
    echo "Usage: workspace create <slug> | list [--json] | here [--json]"
    echo "       workspace directory|file add|remove <slug> <path>"
    echo "       workspace run <name> [--workspace <slug>] [-- <args>...]"
}

# workspace_root(input: Text)
workspace_root__38_v0() {
    local input_18="${1}"
    [[ "${input_18}" == /* ]]
    __status=$?
    if [ "${__status}" != 0 ]; then
        error__0_v0 "WORKSPACE_HOME must be an absolute path" 2
    fi
    real_path__2_v0 "${input_18}">/dev/null 2>&1
    __status=$?
    if [ "${__status}" != 0 ]; then
        ret_workspace_root38_v0="${input_18}"
        return 0
    fi
    local resolved_21="${ret_real_path2_v0}"
    ret_workspace_root38_v0="${resolved_21}"
    return 0
}

typeset -r args_0=("$0" "$@")
umask 077
__status=$?
env_or__1_v0 "HOME" ""
home_7="${ret_env_or1_v0}"
if [ "$([ "_${home_7}" != "_" ]; echo $?)" != 0 ]; then
    error__0_v0 "HOME is required" 1
fi
env_or__1_v0 "WORKSPACE_HOME" "${home_7}/.workspaces"
ret_env_or1_v0__21_33="${ret_env_or1_v0}"
workspace_root__38_v0 "${ret_env_or1_v0__21_33}"
root_22="${ret_workspace_root38_v0}"
__length_26=("${args_0[@]}")
if [ "$(( ${#__length_26[@]} == 1 ))" != 0 ]; then
    error__0_v0 "Expected a workspace command; use --help" 2
fi
action_23="${args_0[1]?"Index out of bounds (at src/main.ab:23:25)"}"
if [ "$(( $([ "_${action_23}" != "_--help" ]; echo $?) || $([ "_${action_23}" != "_-h" ]; echo $?) ))" != 0 ]; then
    usage__37_v0 
    exit 0
fi
if [ "$([ "_${action_23}" != "_create" ]; echo $?)" != 0 ]; then
    __length_27=("${args_0[@]}")
    if [ "$(( ${#__length_27[@]} != 3 ))" != 0 ]; then
        error__0_v0 "Usage: workspace create <slug>" 2
    fi
    create_workspace__20_v0 "${root_22}" "${args_0[2]?"Index out of bounds (at src/main.ab:30:37)"}"
    exit 0
fi
if [ "$(( $([ "_${action_23}" != "_list" ]; echo $?) || $([ "_${action_23}" != "_here" ]; echo $?) ))" != 0 ]; then
    as_json_60=0
    __length_28=("${args_0[@]}")
    if [ "$(( ${#__length_28[@]} == 3 ))" != 0 ]; then
        as_json_60="$([ "_${args_0[2]?"Index out of bounds (at src/main.ab:35:44)"}" != "_--json" ]; echo $?)"
    fi
    __length_29=("${args_0[@]}")
    __length_30=("${args_0[@]}")
    if [ "$(( $(( ${#__length_29[@]} > 3 )) || $(( $(( ${#__length_30[@]} == 3 )) && $(( ! as_json_60 )) )) ))" != 0 ]; then
        error__0_v0 "Usage: workspace ${action_23} [--json]" 2
    fi
    current_61=""
    if [ "$([ "_${action_23}" != "_here" ]; echo $?)" != 0 ]; then
        command_31="$(pwd -P)"
        __status=$?
        if [ "${__status}" != 0 ]; then
            error__0_v0 "Could not resolve the current directory" 1
        fi
        current_61="${command_31}"
    fi
    list_workspaces__21_v0 "${root_22}" "${current_61}" "${as_json_60}"
    exit 0
fi
if [ "$(( $([ "_${action_23}" != "_directory" ]; echo $?) || $([ "_${action_23}" != "_file" ]; echo $?) ))" != 0 ]; then
    __length_32=("${args_0[@]}")
    if [ "$(( ${#__length_32[@]} != 5 ))" != 0 ]; then
        error__0_v0 "Usage: workspace ${action_23} add|remove <slug> <path>" 2
    fi
    key_82="directories"
    if [ "$([ "_${action_23}" != "_file" ]; echo $?)" != 0 ]; then
        key_82="files"
    fi
    update_reference__22_v0 "${root_22}" "${key_82}" "${args_0[2]?"Index out of bounds (at src/main.ab:48:42)"}" "${args_0[3]?"Index out of bounds (at src/main.ab:48:51)"}" "${args_0[4]?"Index out of bounds (at src/main.ab:48:60)"}"
    exit 0
fi
if [ "$([ "_${action_23}" != "_run" ]; echo $?)" != 0 ]; then
    workspace_run__29_v0 "${root_22}" args_0[@]
    exit 0
fi
error__0_v0 "Unknown workspace command: ${action_23}" 2
