# 1. Read Configuration from Properties File
Write-Host "Reading config file"
$configFile = Get-Content "sample_config.properties" 

# Read configuration values and trim whitespace
$config = @{}

foreach($line in $configFile)
{
    # Split each line into key-value pairs using '=' as the delimiter, limiting to 2 substrings 
    # to handle potential '=' within the value
    $words = $line.Split('=',2)
    $config.add($words[0].Trim(), $words[1].Trim())
}

$userEmail = $config["userEmail"].Trim()
$apiToken = $config["apiToken"].Trim() 
$orgId = $config["orgId"].Trim()
$accessToken = $config["access_token"].Trim()
$baseUrl = $config["baseUrl"].Trim()

# 2. Process each row in the CSV
Import-Csv sample_emails.csv | ForEach-Object {
    $oldEmail = $_.oldEmail.Trim()
    $newEmail = $_.newEmail.Trim()

    # 3a. Construct user search API URL
    $encodedOldEmail = [uri]::EscapeDataString($oldEmail)
    $searchUrl = "$baseUrl/rest/api/3/user/search?query=$encodedOldEmail"

    # 3b. Make GET request to user search API
    $Text = "${userEmail}:${apiToken}"

    $Bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
    $authorization = [Convert]::ToBase64String($Bytes)


    try {
        $searchResponse = Invoke-WebRequest -Uri $searchUrl -Method Get -Headers @{"Accept"="application/json"; 'Authorization' = "Basic $authorization" } -UseBasicParsing -ErrorAction Stop

        # 3c. Check if API request was successful
        if ($searchResponse.StatusCode -eq 200) {
        

            # 3ci. Parse JSON response
            $accountId = ($searchResponse.Content | ConvertFrom-Json).accountId
            Write-Host "User Found with $oldEmail Adress account ID is :$accountId"

            # 3cii. Check if response contains user data
            if ($accountId) {

                # 3cii.2 Construct user deletion API URL 
                 $deleteUrl = "https://api.atlassian.com/admin/user-provisioning/v1/org/$orgId/user/$accountId/onlyDeleteUserInDB"

                # 3cii.3 Make DELETE request to user deletion API 
                 $deleteResponse = Invoke-WebRequest -Uri $deleteUrl -Method Delete -Headers @{"Authorization"="Bearer $accessToken"} 

                # 3cii.4 Check if deletion was successful 
                 if ($deleteResponse.StatusCode -eq 204) { # Assuming 204 No Content for successful deletion
                     Write-Host "User with old email $oldEmail deleted successfully!"

                    # 3cii.4a Construct email update API URL
                    $updateUrl = "https://api.atlassian.com/users/$accountId/manage/email"

                    # 3cii.4b Make PUT request to email update API
                    $body = @{ email = $newEmail } | ConvertTo-Json 

                    try {
                        $updateResponse = Invoke-WebRequest -Uri $updateUrl -Method Put -Headers @{"Authorization"="Bearer $accessToken"; "Content-Type"="application/json"} -Body $body -ErrorAction Stop -Verbose

                        # 3cii.4c Check if update was successful
                        if ($updateResponse.StatusCode -eq 204) {
                            Write-Host "Email for user with old email $oldEmail updated to $newEmail successfully!"

                            # If userEmail was updated, also update it in the config for future API calls
                            if ($oldEmail -eq $config["userEmail"].Trim()) {
                                $config["userEmail"] = $newEmail
                            }
                        } else {
                            Write-Host "Error updating email for user with old email $oldEmail. Status Code: $($updateResponse.StatusCode). Response Body: $($updateResponse.Content)" 
                        }
                    } catch {
                        Write-Host "An error occurred while updating the email: $($_.Exception.Message)"
                    }

                 } else {
                     Write-Host "Error deleting user with old email $oldEmail. Response: $($deleteResponse.Content)"
                 }

            # 3cii.iii No user found
            } else {
                Write-Host "No user found with email $oldEmail."
            }

        # 3d. User search API error
        } else {
            Write-Host "Error fetching user data for email $oldEmail. Status Code: $($searchResponse.StatusCode). Response Body: $($searchResponse.Content)"
        }
    } catch {
        Write-Host "An error occurred during the user email Update: $($_.Exception.Message)"
    }
}