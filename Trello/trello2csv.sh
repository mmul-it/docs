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
[ "$1" == "-h" ] && usage && exit 1
[ $# -lt 2 ] && usage && exit 1

# Trello API
TRELLO_KEY='PUT YOUR KEY HERE'
TRELLO_TOKEN='PUT YOUR TOKEN HERE'

TRELLO_USERNAME="$1"

# Generic call to Trello API
trello_api () {
	ENDPOINT="$1"
	FIELDS="$2"

	http --pretty none -b https://api.trello.com/1${ENDPOINT} key==${TRELLO_KEY} token==${TRELLO_TOKEN} fields==${FIELDS}
}

# Obtain the board ID
BOARD_NAME="$2"
BOARD_ID="$(trello_api "/members/${TRELLO_USERNAME}/boards" id,name | jq -r '.[] | [ .id, .name ] | @csv' | sed -e s/\"//g | grep "${BOARD_NAME}" | awk -F',' '{print $1}')"
[ ${#BOARD_ID} -eq 0 ] && echo "Cannot find board named $BOARD_NAME" && exit 1

# Set \n as a field separator
IFS="
"

# Print csv header
echo "Status;Title;Worked By;Due Date"

# Obtain list in boards
for LIST in $(trello_api "/boards/${BOARD_ID}/lists" id,name | jq -r '.[] | [ .id, .name ] | @csv' | sed -e s/\"//g); do
	# Extract list ID and name
	LIST_ID="$(echo $LIST | cut -d',' -f1)"
	LIST_NAME="$(echo $LIST | cut -d',' -f2)"

	# If requested, skip this list
	[ ${#3} -ne 0 ] && [ "${3}" == "${LIST_NAME}" ] && continue

	# Obtain cards in list
	for CARD in $(trello_api "/lists/${LIST_ID}/cards" id,name,due | jq -r '.[] | [ .id, .name, .due ] | @csv' | sed -e s/\"//g); do
		# Extract card ID, Name and Due Date
		CARD_ID="$(echo $CARD | cut -d',' -f1)"
		CARD_NAME="$(echo $CARD | cut -d',' -f2)"
		CARD_DUE="$(echo $CARD | cut -d',' -f3 | cut -d'T' -f1)"

		# Obtain card members
		CARD_MEMBERS="$(trello_api "/cards/${CARD_ID}/members" fullName | jq -r '.[] | [.fullName] | @csv' | sed -e s/\"//g | tr '\n' ',' | sed -e s/,$//)"

		# Write the ouput, avoiding Due Date for the "Done" list
		if [ "${LIST_NAME}" == "Done" ]; then
			echo "${LIST_NAME};${CARD_NAME};${CARD_MEMBERS};"
		else
			echo "${LIST_NAME};${CARD_NAME};${CARD_MEMBERS};${CARD_DUE}"
		fi
	done
done
