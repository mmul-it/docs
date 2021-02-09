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
	echo
	echo "usage: $0 <username> <board_name> [list_to_exclude]"
	echo
	echo "   You must specify the Trello user name and the board name"
	echo "   If you pass a list to exclude, it will not be created in the csv"
	echo
}
[[ "$1" == "-h" ]] && usage && exit 1
[[ $# -lt 2 ]] && usage && exit 1

# Trello API Key and Token are environment variables
# source file (if exists)
[[ -f 'trello2csv.env' ]] && source trello2csv.env

TRELLO_USERNAME="$1"

# Generic call to Trello API
trello_api () {
	ENDPOINT="$1"
	FIELDS="$2"

	curl -sG "https://api.trello.com/1${ENDPOINT}" \
	-d key="${TRELLO_KEY}" \
	-d token="${TRELLO_TOKEN}" \
	-d fields="${FIELDS}"
}

# Separator used in jq output
# (avoid anything that could be used in card title
# as ',', ';', '|', '-', '~')
jq_sep="¬"

# Obtain the board ID
BOARD_NAME="${2}"
BOARD_ID="$(
	trello_api "/members/${TRELLO_USERNAME}/boards" "id,name" \
	| jq -r ".[] | .id+\"${jq_sep}\"+.name" \
	| awk -F"${jq_sep}" "\$2 == \"${BOARD_NAME}\" {print \$1}"
)"
[[ -z "${BOARD_ID}" ]] && echo "Cannot find board named ${BOARD_NAME}" && exit 1

# Print csv header
echo "Status;Title;Worked By;Due Date;Last Activity Date"

# Obtain list in boards
while IFS="${jq_sep}" read -r LIST_ID LIST_NAME
do
	# If requested, skip this list
	[[ -n "${3}" ]] && [[ "${3}" == "${LIST_NAME}" ]] && continue

	# Obtain cards in list
	# - Extract card ID, Name and Due Date
	while IFS="${jq_sep}" read -r CARD_ID CARD_NAME CARD_DUE CARD_LAST_ACTIVITY
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
	done < <(
		trello_api "/lists/${LIST_ID}/cards" "id,name,due,dateLastActivity" \
		| jq -r ".[] | .id+\"${jq_sep}\"+.name+\"${jq_sep}\"+.due+\"${jq_sep}\"+.dateLastActivity" \
		| tr -d '"'
	)
done < <(
	trello_api "/boards/${BOARD_ID}/lists" "id,name" \
	| jq -r ".[] | .id+\"${jq_sep}\"+.name " \
	| tr -d '"'
)
