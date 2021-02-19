#!/bin/bash
#
# This script will get all Trello cards, divided by list, in a specific board
# and export those in CSV.
#
# Require:
# - httpie (https://httpie.org)
# - jq (https://stedolan.github.io/jq/)

# trello2csv.sh usage
usage () {
	cat <<-USAGE
	usage: $0 <board_name> [list_to_exclude]
	
	   You must specify the Trello board name
	   If you pass a list to exclude, it will not be created in the csv
	USAGE
}
[[ $# -lt 1 || "$1" == "-h" ]] && usage && exit 1

# Trello API Key, Token and Username are environment variables
if [[ -z "${TRELLO_KEY}" || -z "${TRELLO_TOKEN}" || -z "${TRELLO_USERNAME}" ]]
then
	# source env file (if exists)
	[[ -f 'trello2csv.env' ]] && source trello2csv.env
fi
[[ -z "${TRELLO_KEY}" || -z "${TRELLO_TOKEN}" ]] && usage && exit 1

# Obtain the board ID
BOARD_NAME="${1}"
SKIP_LIST="${2}"
# Separator used in jq output
# (avoid anything that could be used in card title
# as ',', ';', '|', '-', '~')
jq_sep="¬"

# Generic call to Trello API
trello_api () {
	ENDPOINT="$1"
	FIELDS="$2"

	curl -sG "https://api.trello.com/1${ENDPOINT}" \
	-d key="${TRELLO_KEY}" \
	-d token="${TRELLO_TOKEN}" \
	-d fields="${FIELDS}"
}

# Main programm
BOARD_ID="$(
	trello_api "/members/${TRELLO_USERNAME}/boards" "id,name" \
	| jq -r ".[] | .id+\"${jq_sep}\"+.name" \
	| awk -F"${jq_sep}" "\$2 == \"${BOARD_NAME}\" {print \$1}"
)"
[[ -z "${BOARD_ID}" ]] && echo "Cannot find board named ${BOARD_NAME}" && exit 1

# Print csv header
echo "Status;Title;Worked By;Due Date;Last Activity Date"

# Obtain list in boards
trello_api "/boards/${BOARD_ID}/lists" "id,name" \
	| jq -r ".[] | .id+\"${jq_sep}\"+.name " \
	| tr -d '"' \
	| while IFS="${jq_sep}" read -r LIST_ID LIST_NAME
do
	# If requested, skip this list
	[[ -n "${SKIP_LIST}" && "${SKIP_LIST}" == "${LIST_NAME}" ]] && continue

	# Obtain cards in list
	# - Extract card ID, Name and Due Date
	trello_api "/lists/${LIST_ID}/cards" "id,name,due,dateLastActivity" \
		| jq -r ".[] | .id+\"${jq_sep}\"+.name+\"${jq_sep}\"+.due+\"${jq_sep}\"+.dateLastActivity" \
		| tr -d '"' \
		| while IFS="${jq_sep}" read -r CARD_ID CARD_NAME CARD_DUE CARD_LAST_ACTIVITY
	do
		# Obtain card members
		CARD_MEMBERS="$(
			trello_api "/cards/${CARD_ID}/members" "fullName" \
			| jq -r '.[] | .fullName' \
			| paste -sd','
		)"

		# Write the ouput, avoiding Due Date for the "Done" list
		if [[ "${LIST_NAME}" == "Done" ]]; then
			echo "${LIST_NAME};${CARD_NAME};${CARD_MEMBERS};;${CARD_LAST_ACTIVITY%T*}"
		else
			echo "${LIST_NAME};${CARD_NAME};${CARD_MEMBERS};${CARD_DUE%T*};${CARD_LAST_ACTIVITY%T*}"
		fi
	done
done
