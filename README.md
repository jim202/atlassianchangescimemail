# README #

This README would normally document whatever steps are necessary to get your application up and running.

### What is this repository for? ###

# ChangeAtlassianUserEmail

This PowerShell script automates the process of updating user email addresses in an Atlassian instance.

## Features

* Reads configuration from a `sample_config.properties` file.
* Processes a CSV file containing old and new email addresses.
* Searches for users in Atlassian using the old email address.
* Optionally deletes users associated with the old email address (commented out by default).
* Updates the user's email address to the new one specified in the CSV.
* Provides basic error handling and verbose output for debugging.

## Prerequisites

* PowerShell (installed on your system)
* Atlassian API access with necessary tokens and permissions
* `sample_config.properties` file (see Configuration below)
* `sample_emails.csv` file (see Usage below)

## Configuration

Create a `sample_config.properties` file in the same directory as the script with the following format:

Replace the placeholders with your actual Atlassian credentials and configuration details.

## Usage

1. Prepare your CSV file:

* Create a CSV file named `sample_emails.csv` with the following columns:

* Populate the CSV with the old email addresses you want to update and their corresponding new email addresses.

2. Run the script:

```powershell
.\ChangeAtlassianUserEmail.ps1
