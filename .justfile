TARGET := if os() == "windows" { error("this convenience script currently does not support windows") } else if os() == "macos" { "macos-{{arch()}}" } else { os() }
WPT_DL_URL := "https://github.com/JohnnyMorganz/wally-package-types/releases/download/v1.3.1/wally-package-types-" + TARGET + ".zip"
CWD := invocation_directory()

[private]
default:
    #!/usr/bin/env bash
    set -euo pipefail
    
    just check_env
    printf "[*] " && just --list

check_env:
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "[*] Checking whether required tools are installed"

    declare -a deps=("lune" "rojo" "wally-package-types" "wally")

    for dep in ${deps[@]}
    do
        if ! which "$dep" &>/dev/null; then
            echo "  => [!] Dependency $dep not found!"
            
            if [[ "$dep" == "wally-package-types" ]]; then
                echo "      => [*] Installing wally-package-types..."
                
                cd /tmp
                wget -q --show-progress --progress=bar:force -O "wally-package-types.zip" "{{WPT_DL_URL}}"
                unzip wally-package-types.zip 1>/dev/null
                mv wally-package-types "$HOME/.local/bin/wally-package-types"
            else
                exit 1
            fi
        else
            echo "   => [*] FOUND: $dep"
        fi
    done


[no-cd]
setup PROJECT_NAME *TYPE:
    #!/usr/bin/env bash
    set -euo pipefail

    just check_env

    function setup_lune() {
        echo "[*] Setting up lune typedefs..."
        lune setup 
    }

    function setup_wally() {
        echo "[*] Installing dependencies with wally..."
        wally install
    }

    cd "{{CWD}}/Modules/{{PROJECT_NAME}}"

    if [[ "{{TYPE}}" == "lune" ]]; then
        setup_lune
    elif [[ "{{TYPE}}" == "wally" ]]; then
        setup_wally
    else
        setup_lune && setup_wally
    fi
    
[no-cd]
update_sourcemap PROJECT_NAME:
    #!/usr/bin/env bash
    set -euo pipefail
    
    just check_env
    echo "[*] Updating sourcemap for {{PROJECT_NAME}}..."
    cd "{{CWD}}/Modules/{{PROJECT_NAME}}"

    rojo sourcemap development.project.json --output sourcemap.json 
    wally-package-types --sourcemap sourcemap.json Packages/

[no-cd]
serve PROJECT_NAME BUILD_TYPE:
    #!/usr/bin/env bash
    set -euo pipefail

    just check_env
    echo "[*] Starting rojo {{BUILD_TYPE}} session for {{PROJECT_NAME}}..."
    cd "{{CWD}}/Modules/{{PROJECT_NAME}}"

    rojo serve "{{BUILD_TYPE}}.project.json"

[no-cd]
build PROJECT_NAME BUILD_TYPE:
    #!/usr/bin/env bash
    set -euo pipefail

    just check_env
    echo "[*] Building {{BUILD_TYPE}} build for {{PROJECT_NAME}}..."
    cd "{{CWD}}/Modules/{{PROJECT_NAME}}"

    rojo build "{{BUILD_TYPE}}.project.json" -o "{{PROJECT_NAME}}-Build.rbxl"

[no-cd]
lint PROJECT_NAME:
    #!/usr/bin/env bash
    set -euo pipefail
    
    just check_env
    echo "[*] Linting {{PROJECT_NAME}}..."
    cd "{{CWD}}/Modules/{{PROJECT_NAME}}"

    selene Source
