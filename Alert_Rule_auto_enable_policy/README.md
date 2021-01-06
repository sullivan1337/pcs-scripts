# Prisma Cloud Alert Rules

## Used to automatically go in to an Alert Rule and auto-select all new Policies of the chosen severity added and enabled since creation

What these will do will scan ALL policies (just choose the severity you want, normally HIGH) within your Prisma Cloud environment, and then depending on the Severity chosen (Low, Medium, High), will add ALL of the Policies to the existing Alert Rule. 

1. Use the *curl_GET* or the *GET_all* script to get the correct **policyScanConfigId**(s) that you will use as the input for all other scripts

1. Select the script with the Policy severity that you want to auto-select for the existing Alert Rule(s)

### That's it!

As always, if anything is incorrect or needs updated, please submit a PR and will take a look.
