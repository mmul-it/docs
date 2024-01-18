# trello2csv - Export Trello boards as CSV file

This script automates the Trello exporting in a CSV file, and it's really
usefull to convert a Trello board status in a table to share with other people
or customers.

It needs two software to work:

* [jq](https://stedolan.github.io/jq/) - a JSON parser for the command line
* [cURL](https://curl.se/) - the classic CLI HTTP client

cURL can be easly replaced by other CLI client (such [HTTPie](https://httpie.org))
if you prefer (look at the `trello_api()` function).

## Installation

First of all, you need the Trello Key and Trello Token in order to perform API
calls. Go to the [Trello Developer API Keys page](https://trello.com/app-key/)
and follow the intructions.
Once obtained the two values, edit `trello2csv.env` and replace the two lines:

```bash
export TRELLO_KEY='PUT YOUR KEY HERE'
export TRELLO_TOKEN='PUT YOUR TOKEN HERE'
```

with the correct values.

In the same file, edit also the `TRELLO_USERNAME`:

```bash
export TRELLO_USERNAME='PUT YOUR USERNAME HERE'
```

To keep pulling this repo without changes to `trello2csv.env`, set the file
"as unchanged":

```console
$ git update-index --assume-unchanged trello2csv.env
(no output)
```

## Usage

In order to use trello2csv, you need to pass one parameter:

* `board_name`: the Trello board to export (case sensitive).

The subsequent parameters, if present, are the list to be excluded from CSV
report:

* `exclude_list`: the name of a list to exclude from the export process
  (case sensitive).

The script will output a CSV table ready for importing in your favorite office
application. The table will have the following columns:

* Status: the list name.
* Title: the card title.
* Worked By: the list of card members.
* Due Date: the card due date (not printed if the list is named "Done").
* Last Activity Date: last time the card was modified.
* Labels: the label(s) name(s) associated to the card (if any).

Here a usage example:

```console
$ ./trello2csv.sh "My Customer"
Status;Title;Worked By;Due Date;Last Activity Date
Tech Debts;Nagios role (separate server-worker);;;2020-07-17
To Do;Remove personal signs in text files;Mario Rossi,Andrea Verdi;2020-08-20;2020-08-18
...
```

And excluding "Tech Debts" list:

```console
$ ./trello2csv.sh "My Customer" "Tech Debts"
Status;Title;Worked By;Due Date;Last Activity Date
To Do;Remove personal signs in text files;Mario Rossi,Andrea Verdi;2020-08-20;2020-08-18
...
```

You can redirect the output in a CSV file and easly import in your favourite
application.
