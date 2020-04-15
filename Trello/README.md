# trello2csv - Export Trello boards as CSV file

This script automates the Trello exporting in a CSV file, and it's really
usefull to convert a Trello board status in a table to share with other people
or customers.

It needs two software to work:

* [jq](https://stedolan.github.io/jq/) - a JSON parser for the command line
* [httpie](https://httpie.org) - a command line HTTP client with intuitive UI

HTTPie can be easly replaced by curl if you prefer (look at the trello_api()
function).

## Installation

First of all, you need the Trello Key and Trello Token in order to perform API
calls. Go to the [Trello Developer API Keys page](https://trello.com/app-key/)
and follow the intructions. Once obtained the two values, edit trello2csv.sh and
replace the two lines:

    TRELLO_KEY='PUT YOUR KEY HERE'
    TRELLO_TOKEN='PUT YOUR TOKEN HERE'

with the correct values.

## Usage

In order to use trello2csv, you need to pass 3 parameters:

* username: your Trello username
* board_name: the Trello board to export (case sensitive)
* list_to_exclude: the name of a list to exclude from the export process
  (case sensitive)

The script will output a CSV table ready for importing in your favorite office
application. The table will have the following columns:

* Status: the list name
* Title: the card title
* Worked By: the list of card members
* Due Date: the card due date (not printed if the list is named "Done")

Here a usage example:

    $ ./trello2csv.sh mariorossi "My Customer"
	Status;Title;Worked By;Due Date
	Tech Debts;Ruolo nagios (funzionamento server-worker combinato);;
	To Do;Rimozione di tutte le firme all'interno dei file di testo;Mario Rossi,Andrea Verdi;2020-08-20
	...

You can redirect the output in a CSV file and easly import in your favourite
application.